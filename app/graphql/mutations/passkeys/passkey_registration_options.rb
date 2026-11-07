# frozen_string_literal: true

class Mutations::Passkeys::PasskeyRegistrationOptions < Mutations::BaseMutation
  description "Start adding a passkey to the current user's account. Returns the options to pass to `navigator.credentials.create` (PublicKeyCredentialCreationOptionsJSON). Requires the current password and a confirmed email address."

  # Asking for the password means a stolen session token alone can't add a
  # passkey (which would outlive a password reset). registerPasskey can only
  # use a challenge issued here, so this is the only place it's checked.
  argument :current_password, String, required: true, description: "The user's current password for verification."

  field :options, GraphQL::Types::JSON, null: true, description: "PublicKeyCredentialCreationOptionsJSON for the browser's WebAuthn API. `null` if there are errors."
  field :errors, [String], null: false, description: "Error messages if a passkey can't be added."

  def resolve(current_password:)
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to add a passkey." if user.nil?

    return { options: nil, errors: ["Current password is incorrect."] } unless user.valid_password?(current_password)

    return { options: nil, errors: ["Confirm your email address before adding a passkey."] } unless user.confirmed?

    return { options: nil, errors: ["You can't add more than #{WebauthnCredential::MAX_PER_USER} passkeys."] } if user.webauthn_credentials.count >= WebauthnCredential::MAX_PER_USER

    options = WebAuthn::Credential.options_for_create(
      user: { id: user.webauthn_id!, name: user.email, display_name: user.username },
      # Stops the browser from making a second passkey on an authenticator
      # that already has one for this account.
      exclude: user.webauthn_credentials.pluck(:external_id),
      # Discoverable credentials are what let a passkey sign in from the
      # email field without typing anything, and user verification (biometrics
      # or a PIN) makes the passkey a full replacement for the password.
      authenticator_selection: { resident_key: 'required', require_resident_key: true, user_verification: 'required' }
    )
    WebauthnChallenge.issue!(challenge: options.challenge, purpose: :registration, user: user)

    { options: options.as_json, errors: [] }
  end
end
