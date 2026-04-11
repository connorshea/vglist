# frozen_string_literal: true

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

    it 'includes the jwt_version in the payload' do
      token = described_class.encode(user)
      decoded = described_class.decode(token)
      expect(decoded.first['jwt_version']).to eq(user.jwt_version)
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

  describe '.decode_and_verify' do
    it 'returns the user for a valid token' do
      token = described_class.encode(user)
      expect(described_class.decode_and_verify(token)).to eq(user)
    end

    it 'returns nil after the token has been revoked' do
      token = described_class.encode(user)
      described_class.revoke_all!(user)
      expect(described_class.decode_and_verify(token)).to be_nil
    end

    it 'returns nil for an invalid token' do
      expect(described_class.decode_and_verify('invalid.token.string')).to be_nil
    end

    it 'returns nil for a token missing jwt_version' do
      payload = { user_id: user.id, exp: 1.day.from_now.to_i, iat: Time.current.to_i }
      token = JWT.encode(payload, described_class.secret_key, 'HS256')
      expect(described_class.decode_and_verify(token)).to be_nil
    end
  end

  describe '.revoke_all!' do
    it 'increments the user jwt_version' do
      expect { described_class.revoke_all!(user) }.to change { user.reload.jwt_version }.by(1)
    end

    it 'invalidates all previously issued tokens' do
      token1 = described_class.encode(user)
      token2 = described_class.encode(user)
      described_class.revoke_all!(user)
      expect(described_class.decode_and_verify(token1)).to be_nil
      expect(described_class.decode_and_verify(token2)).to be_nil
    end

    it 'allows tokens issued after revocation' do
      described_class.revoke_all!(user)
      new_token = described_class.encode(user.reload)
      expect(described_class.decode_and_verify(new_token)).to eq(user)
    end
  end
end
