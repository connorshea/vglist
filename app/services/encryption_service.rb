# A service for encrypting/decrypting values.
#
# Based on this blog post:
# https://pawelurbanek.com/rails-secure-encrypt-decrypt
class EncryptionService
  # Only define the fallbacks in development, otherwise leave them unset.
  FALLBACK_KEY = Rails.env.development? ? 'foo' : nil
  FALLBACK_SALT = Rails.env.development? ? 'bar' : nil

  # Use the fallback key if no credentials.yml exists. Will work for
  # development and fail in production. We don't want to use the fallback in
  # production because that'd be insecure.
  KEY = ActiveSupport::KeyGenerator.new(
    Rails.application.credentials.fetch(:secret_key_base, FALLBACK_KEY)
  ).generate_key(
    Rails.application.credentials.fetch(:encryption_service_salt, FALLBACK_SALT),
    ActiveSupport::MessageEncryptor.key_len
  ).freeze

  private_constant :KEY

  delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

  def self.encrypt(value)
    new.encrypt_and_sign(value)
  end

  def self.decrypt(value)
    new.decrypt_and_verify(value)
  end

  private

  def encryptor
    ActiveSupport::MessageEncryptor.new(KEY)
  end
end
