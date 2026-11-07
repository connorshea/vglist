# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebauthnCredential, type: :model do
  subject(:credential) { build(:webauthn_credential) }

  describe 'validations' do
    it { should validate_presence_of(:external_id) }
    it { should validate_uniqueness_of(:external_id) }
    it { should validate_presence_of(:public_key) }
    it { should validate_length_of(:nickname).is_at_most(60) }
    it { should validate_numericality_of(:sign_count).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'nickname' do
    it 'falls back to a default when blank' do
      credential.nickname = '   '
      credential.validate
      expect(credential.nickname).to eq('Unnamed passkey')
    end

    it 'squishes whitespace' do
      credential.nickname = "  My   phone \n"
      credential.validate
      expect(credential.nickname).to eq('My phone')
    end
  end

  it 'is deleted along with its user' do
    credential.save!
    expect { credential.user.destroy }.to change(described_class, :count).by(-1)
  end
end
