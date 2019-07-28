# typed: false
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

  describe 'Destructions' do
    let(:game_purchase) { create(:game_purchase) }
    let(:platform) { create(:platform) }
    let(:game_purchase_platform) { create(:game_purchase_platform, game_purchase: game_purchase, platform: platform) }

    it 'GamePurchase should not be deleted when game purchase platform is deleted' do
      game_purchase_platform
      expect { game_purchase_platform.destroy }.to change(GamePurchase, :count).by(0)
    end

    it 'Platform should not be deleted when game purchase platform is deleted' do
      game_purchase_platform
      expect { game_purchase_platform.destroy }.to change(Platform, :count).by(0)
    end
  end
end
