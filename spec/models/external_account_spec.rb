require 'rails_helper'

RSpec.describe ExternalAccount, type: :model do
  subject(:external_account) { FactoryBot.create(:external_account) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(external_account).to be_valid
    end

    it 'validates uniqueness' do
      expect(external_account).to validate_uniqueness_of(:user_id)
        .scoped_to(:account_type)
    end

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:account_type) }

    it 'validates numericality of steam_id' do
      expect(external_account).to validate_numericality_of(:steam_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end

    it 'has an account type with a possible value of steam' do
      expect(external_account).to define_enum_for(:account_type)
        .with_values([:steam])
    end
  end

  describe "Associations" do
    it { should belong_to(:user) }
  end

  describe 'Destructions' do
    let(:external_account) { create(:external_account) }
    let(:user_with_external_account) { create(:user, external_account: external_account) }

    it 'User should not be deleted when external account is deleted' do
      user_with_external_account
      expect { external_account.destroy }.to change(User, :count).by(0)
    end
  end
end
