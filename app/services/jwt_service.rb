# frozen_string_literal: true

class JwtService
  ALGORITHM = 'HS256'
  EXPIRY = 30.days

  def self.encode(user)
    payload = {
      user_id: user.id,
      jwt_version: user.jwt_version,
      exp: EXPIRY.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, secret_key, true, algorithms: [ALGORITHM])
  end

  # Decode a token and verify that its jwt_version matches the user's
  # current jwt_version. Returns the User or nil.
  def self.decode_and_verify(token)
    decoded = decode(token)
    payload = decoded.first
    user = User.find(payload['user_id'])

    # Reject tokens issued before the user's current jwt_version.
    return nil if payload.fetch('jwt_version', -1) != user.jwt_version

    user
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  # Increment the user's jwt_version to invalidate all existing tokens.
  def self.revoke_all!(user)
    user.jwt_version += 1
    user.save!
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end
