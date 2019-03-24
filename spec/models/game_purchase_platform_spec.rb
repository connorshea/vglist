require 'rails_helper'

RSpec.describe GamePurchasePlatform, type: :model do
  subject(:game_purchase_platform) { FactoryBot.create(:game_purchase_platform) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase_platform).to be_valid
    end

    it { should validate_uniqueness_of(:game_purchase_id).scoped_to(:platform_id) }
  end

  describe "Associations" do
    it { should belong_to(:game_purchase) }
    it { should belong_to(:platform) }
  end

  describe "Indexes" do
    it { should have_db_index([:game_purchase_id, :platform_id]).unique }
  end
end
