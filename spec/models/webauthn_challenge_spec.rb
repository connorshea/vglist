# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebauthnChallenge, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }

  describe 'validations' do
    it 'requires a user for registration challenges' do
      challenge = described_class.new(challenge: 'abc', purpose: :registration, expires_at: 1.minute.from_now)
      expect(challenge).not_to be_valid
    end

    it 'does not require a user for authentication challenges' do
      challenge = described_class.new(challenge: 'abc', purpose: :authentication, expires_at: 1.minute.from_now)
      expect(challenge).to be_valid
    end
  end

  describe '.issue!' do
    it 'stores a challenge that expires after the TTL' do
      freeze_time do
        challenge = described_class.issue!(challenge: 'abc', purpose: :authentication)
        expect(challenge.expires_at).to eq(WebauthnChallenge::TTL.from_now)
      end
    end

    it 'sweeps expired challenges', :aggregate_failures do
      described_class.issue!(challenge: 'old', purpose: :authentication)

      travel(WebauthnChallenge::TTL + 1.second) do
        described_class.issue!(challenge: 'new', purpose: :authentication)
      end

      expect(described_class.pluck(:challenge)).to eq(['new'])
    end
  end

  describe '.consume' do
    it 'consumes a challenge once', :aggregate_failures do
      described_class.issue!(challenge: 'abc', purpose: :authentication)

      expect(described_class.consume(challenge: 'abc', purpose: :authentication)).to be(true)
      expect(described_class.consume(challenge: 'abc', purpose: :authentication)).to be(false)
    end

    it 'rejects an expired challenge' do
      described_class.issue!(challenge: 'abc', purpose: :authentication)

      travel(WebauthnChallenge::TTL + 1.second) do
        expect(described_class.consume(challenge: 'abc', purpose: :authentication)).to be(false)
      end
    end

    it 'rejects a challenge issued for another purpose' do
      described_class.issue!(challenge: 'abc', purpose: :registration, user: user)
      expect(described_class.consume(challenge: 'abc', purpose: :authentication)).to be(false)
    end

    it 'rejects a registration challenge issued to another user' do
      described_class.issue!(challenge: 'abc', purpose: :registration, user: user)
      expect(described_class.consume(challenge: 'abc', purpose: :registration, user: create(:confirmed_user))).to be(false)
    end

    it 'accepts a registration challenge for the user it was issued to' do
      described_class.issue!(challenge: 'abc', purpose: :registration, user: user)
      expect(described_class.consume(challenge: 'abc', purpose: :registration, user: user)).to be(true)
    end

    it 'rejects a blank challenge' do
      expect(described_class.consume(challenge: nil, purpose: :authentication)).to be(false)
    end
  end
end
