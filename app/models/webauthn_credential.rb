# frozen_string_literal: true

# A passkey (WebAuthn credential) a user has registered for signing in.
class WebauthnCredential < ApplicationRecord
  NICKNAME_MAX_LENGTH = 60
  DEFAULT_NICKNAME = 'Unnamed passkey'
  # Plenty for phones, laptops and a couple of security keys.
  MAX_PER_USER = 20

  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, length: { maximum: NICKNAME_MAX_LENGTH }
  validates :sign_count,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :normalize_nickname

  private

  def normalize_nickname
    self.nickname = nickname.to_s.squish.presence || DEFAULT_NICKNAME
  end
end
