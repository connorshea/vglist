# typed: true

# A service for encrypting/decrypting values.
#
# Based on this blog post:
# https://pawelurbanek.com/rails-secure-encrypt-decrypt
class EncryptionService
  extend T::Sig

  KEY = T.let(ActiveSupport::KeyGenerator.new(
    Rails.application.credentials.secret_key_base
  ).generate_key(
    Rails.application.credentials.encryption_service_salt,
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
