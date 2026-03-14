# frozen_string_literal: true

class JwtService
  ALGORITHM = 'HS256'
  EXPIRY = 30.days

  def self.encode(user)
    payload = {
      user_id: user.id,
      exp: EXPIRY.from_now.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, secret_key, true, algorithms: [ALGORITHM])
  end

  def self.secret_key
    Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
  end
end
