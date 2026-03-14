require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { create(:confirmed_user) }

  describe '.encode' do
    it 'returns a valid JWT string' do
      token = described_class.encode(user)
      expect(token).to be_a(String)
      expect(token.count('.')).to eq(2)
    end

    it 'includes the user_id in the payload' do
      token = described_class.encode(user)
      decoded = described_class.decode(token)
      expect(decoded.first['user_id']).to eq(user.id)
    end

    it 'sets an expiration time' do
      token = described_class.encode(user)
      decoded = described_class.decode(token)
      expect(decoded.first['exp']).to be_present
      expect(decoded.first['exp']).to be > Time.current.to_i
    end

    it 'sets an issued-at time' do
      token = described_class.encode(user)
      decoded = described_class.decode(token)
      expect(decoded.first['iat']).to be_present
      expect(decoded.first['iat']).to be <= Time.current.to_i
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = described_class.encode(user)
      decoded = described_class.decode(token)
      expect(decoded.first['user_id']).to eq(user.id)
    end

    it 'raises JWT::DecodeError for an invalid token' do
      expect { described_class.decode('invalid.token.string') }.to raise_error(JWT::DecodeError)
    end

    it 'raises JWT::ExpiredSignature for an expired token' do
      payload = { user_id: user.id, exp: 1.day.ago.to_i, iat: 2.days.ago.to_i }
      token = JWT.encode(payload, described_class.secret_key, 'HS256')
      expect { described_class.decode(token) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'raises JWT::DecodeError for a token signed with a different key' do
      payload = { user_id: user.id, exp: 1.day.from_now.to_i, iat: Time.current.to_i }
      token = JWT.encode(payload, 'wrong-secret-key', 'HS256')
      expect { described_class.decode(token) }.to raise_error(JWT::DecodeError)
    end
  end
end
