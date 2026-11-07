# frozen_string_literal: true

require 'net/http'

# Checks a Cloudflare Turnstile token against the siteverify API, so sign-up
# can reject requests that didn't come from a browser that passed the
# challenge. See https://developers.cloudflare.com/turnstile/get-started/server-side-validation/
#
# The secret key comes from TURNSTILE_SECRET_KEY, falling back to
# `turnstile.secret_key` in the Rails credentials. When neither is set
# (development, test, self-hosted instances) verification is disabled and
# every request passes.
#
# Verification fails closed: a missing token, a rejected token, or an error
# talking to Cloudflare all count as failures.
class TurnstileVerifier
  SITEVERIFY_URL = URI('https://challenges.cloudflare.com/turnstile/v0/siteverify').freeze

  # Shown to the user when verification fails. Tokens are single-use and
  # expire after 5 minutes, so retrying with a fresh one is the fix.
  ERROR_MESSAGE = "We couldn't verify that you're human. Please complete the challenge and try again."

  # The action the sign-up form's widget renders with (SignupPage.vue).
  SIGN_UP_ACTION = 'signup'

  # Cloudflare's own limit on token length.
  MAX_TOKEN_LENGTH = 2048

  def self.enabled?
    secret_key.present?
  end

  def self.secret_key
    ENV['TURNSTILE_SECRET_KEY'].presence || Rails.application.credentials.dig(:turnstile, :secret_key).presence
  end

  # Returns true when the token is valid, or when verification is disabled.
  #
  # `action` is the action the widget was rendered with. A token minted by a
  # widget with any other action is rejected, so a token from some other
  # Turnstile form can't be replayed here. Cloudflare's dummy test secret
  # keys leave `action` out of the response entirely, so the check only
  # applies when the field is present; real keys always include it.
  def self.verify(token:, action:, remote_ip: nil)
    return true unless enabled?
    return false if token.blank? || token.length > MAX_TOKEN_LENGTH

    body = siteverify(token: token, remote_ip: remote_ip)
    unless body['success'] == true
      Rails.logger.info("Turnstile verification failed: #{Array(body['error-codes']).join(', ')}")
      return false
    end

    if body.key?('action') && body['action'] != action
      Rails.logger.info("Turnstile action mismatch: expected #{action.inspect}, got #{body['action'].inspect}")
      return false
    end

    true
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, IOError,
         OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::ProtocolError, JSON::ParserError => e
    Rails.logger.warn("Turnstile verification errored: #{e.class}: #{e.message}")
    false
  end

  def self.siteverify(token:, remote_ip:)
    form = { secret: secret_key, response: token }
    form[:remoteip] = remote_ip if remote_ip.present?

    response = Net::HTTP.start(SITEVERIFY_URL.host, SITEVERIFY_URL.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      request = Net::HTTP::Post.new(SITEVERIFY_URL)
      request.set_form_data(form)
      http.request(request)
    end

    return {} unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    parsed.is_a?(Hash) ? parsed : {}
  end
  private_class_method :siteverify
end
