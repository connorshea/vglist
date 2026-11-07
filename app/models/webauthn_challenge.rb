# frozen_string_literal: true

# A single-use challenge for a WebAuthn ceremony (registering a passkey or
# signing in with one).
#
# The API is cookie-less (bearer JWTs), so there's no session to keep the
# challenge in between the "options" request and the "verify" request, and
# Rails.cache is per Puma worker in production, so the verify request could
# land on a worker that never saw it. The challenge lives in this table
# instead, and `consume` deletes it in the same statement that checks it, so
# it can't be used twice.
class WebauthnChallenge < ApplicationRecord
  # How long a challenge stays valid. A little longer than the browser-side
  # timeout (WebAuthn.configuration.credential_options_timeout) so a ceremony
  # that finishes right at the end still verifies.
  TTL = 5.minutes

  belongs_to :user, optional: true

  enum :purpose, {
    registration: 0,
    authentication: 1
  }

  validates :challenge, presence: true, uniqueness: true
  validates :purpose, presence: true
  validates :expires_at, presence: true
  validates :user, presence: true, if: :registration?

  scope :expired, -> { where(expires_at: ..Time.current) }

  # Store a challenge the server just handed out. Also sweeps expired rows, so
  # the table stays small without a cron job.
  #
  # @param challenge [String] The base64url challenge from the WebAuthn options.
  # @param purpose [Symbol] :registration or :authentication.
  # @param user [User, nil] The user registering a passkey. nil when signing in.
  # @return [WebauthnChallenge]
  def self.issue!(challenge:, purpose:, user: nil)
    expired.delete_all
    create!(challenge: challenge, purpose: purpose, user: user, expires_at: TTL.from_now)
  end

  # Use up a challenge. Deletes it and returns true only if an unexpired
  # challenge with this value, purpose and user exists, so a second call with
  # the same challenge returns false.
  #
  # @param challenge [String] The base64url challenge from the client data.
  # @param purpose [Symbol] :registration or :authentication.
  # @param user [User, nil] The user it was issued to, for registration.
  # @return [Boolean]
  def self.consume(challenge:, purpose:, user: nil)
    return false if challenge.blank?

    where(challenge: challenge, purpose: purpose, user_id: user&.id)
      .where('expires_at > ?', Time.current)
      .delete_all == 1
  end
end
