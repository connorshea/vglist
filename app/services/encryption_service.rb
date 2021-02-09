# typed: strict

# A service for encrypting/decrypting values.
#
# Based on this blog post:
# https://pawelurbanek.com/rails-secure-encrypt-decrypt
class EncryptionService
  extend T::Sig

  # Only define the fallbacks in development, otherwise leave them unset.
  FALLBACK_KEY = T.let(Rails.env.development? ? 'foo' : nil, T.nilable(String))
  FALLBACK_SALT = T.let(Rails.env.development? ? 'bar' : nil, T.nilable(String))

  # Use the fallback key if no credentials.yml exists. Will work for
  # development and fail in production. We don't want to use the fallback in
  # production because that'd be insecure.
  KEY = T.let(ActiveSupport::KeyGenerator.new(
    Rails.application.credentials.fetch(:secret_key_base, FALLBACK_KEY)
  ).generate_key(
    Rails.application.credentials.fetch(:encryption_service_salt, FALLBACK_SALT),
    ActiveSupport::MessageEncryptor.key_len
  ).freeze, String)

  private_constant :KEY

  delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

  sig { params(value: String).returns(String) }
  def self.encrypt(value)
    new.encrypt_and_sign(value)
  end

  sig { params(value: String).returns(String) }
  def self.decrypt(value)
    new.decrypt_and_verify(value)
  end

  private

  sig { returns(ActiveSupport::MessageEncryptor) }
  def encryptor
    ActiveSupport::MessageEncryptor.new(KEY)
  end
end
