# frozen_string_literal: true

# Verifies the passkey (WebAuthn) responses the SPA gets from
# `navigator.credentials` and sends to the GraphQL API.
module PasskeyService
  # Raised for any problem with a passkey response: malformed input, an
  # unknown, expired or reused challenge, an unknown passkey, or a failed
  # verification. The message is safe to show to the user.
  class Error < StandardError; end

  MALFORMED_MESSAGE = "The passkey response is malformed."
  CHALLENGE_MESSAGE = "This passkey request expired or was already used. Please try again."
  UNKNOWN_PASSKEY_MESSAGE = "That passkey isn't linked to a vglist account."
  VERIFICATION_MESSAGE = "That passkey couldn't be verified."

  module_function

  # Parse a registration response, use up its challenge, and verify it.
  #
  # @param response [Hash] RegistrationResponseJSON from `navigator.credentials.create`.
  # @param user [User] The signed-in user who requested the options.
  # @return [WebAuthn::PublicKeyCredentialWithAttestation]
  def verify_registration(response, user:)
    credential, challenge = parse(response) { |hash| WebAuthn::Credential.from_create(hash) }
    consume_challenge!(challenge, purpose: :registration, user: user)

    verify! { credential.verify(challenge, user_verification: true) }
    credential
  end

  # Parse an authentication response, use up its challenge, find the stored
  # passkey, and check the signature against it.
  #
  # @param response [Hash] AuthenticationResponseJSON from `navigator.credentials.get`.
  # @return [WebauthnCredential] The stored passkey, with its sign count and
  #   last-used time updated.
  def verify_authentication(response)
    credential, challenge = parse(response) { |hash| WebAuthn::Credential.from_get(hash) }
    consume_challenge!(challenge, purpose: :authentication)

    stored = WebauthnCredential.includes(:user).find_by(external_id: credential.id)
    raise Error, UNKNOWN_PASSKEY_MESSAGE if stored.nil?

    # The user handle is optional in an assertion, but if the authenticator
    # sent one it has to match the passkey's owner.
    raise Error, UNKNOWN_PASSKEY_MESSAGE if credential.user_handle.present? && credential.user_handle != stored.user.webauthn_id

    # Rejects a sign count that went backwards (a possibly cloned
    # authenticator). Synced passkeys always report 0, which the gem allows.
    verify! do
      credential.verify(challenge, public_key: stored.public_key, sign_count: stored.sign_count, user_verification: true)
    end

    stored.update!(sign_count: credential.sign_count, backed_up: credential.backed_up? || false, last_used_at: Time.current)
    stored
  end

  # Build the credential from the browser's JSON and pull out the challenge
  # it answers. Anything unparseable is reported as malformed.
  #
  # @return [Array(WebAuthn::PublicKeyCredential, String)] The credential and
  #   its base64url challenge.
  def parse(response)
    # The SPA posts JSON, so GraphQL hands the JSON scalar over as
    # ActionController::Parameters rather than a Hash.
    response = response.to_unsafe_h if response.respond_to?(:to_unsafe_h)
    raise Error, MALFORMED_MESSAGE unless response.is_a?(Hash) && response['response'].is_a?(Hash)

    credential = yield response.to_h.deep_stringify_keys
    challenge = WebAuthn.standard_encoder.encode(credential.response.client_data.challenge)
    [credential, challenge]
  rescue Error
    raise
  rescue StandardError
    raise Error, MALFORMED_MESSAGE
  end

  def consume_challenge!(challenge, purpose:, user: nil)
    return if WebauthnChallenge.consume(challenge: challenge, purpose: purpose, user: user)

    raise Error, CHALLENGE_MESSAGE
  end

  # Run a WebAuthn verification, turning its errors (and anything a crafted
  # response could make the gem raise) into PasskeyService::Error.
  def verify!
    yield
  rescue WebAuthn::Error => e
    Rails.logger.info("Passkey verification failed: #{e.class}")
    raise Error, VERIFICATION_MESSAGE
  rescue StandardError => e
    Rails.logger.info("Passkey verification failed: #{e.class}: #{e.message}")
    raise Error, VERIFICATION_MESSAGE
  end
end
