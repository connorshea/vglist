# typed: false
require 'rails_helper'

RSpec.describe Platform, type: :model do
  subject(:platform) { build(:platform) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(platform).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality' do
      expect(platform).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end
  end

  describe "Versioning" do
    it { should be_versioned }
  end

  describe "Associations" do
    it { should have_many(:game_platforms) }
    it { should have_many(:games).through(:game_platforms).source(:game) }
    it { should have_many(:game_purchase_platforms) }
    it { should have_many(:game_purchases).through(:game_purchase_platforms).source(:game_purchase) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
  end

  describe 'Destructions' do
    let(:platform) { create(:platform) }
    let(:game_with_platform) { create(:game, platforms: [platform]) }
    let(:game_purchase) { create(:game_purchase) }
    let(:game_purchase_platform) { create(:game_purchase_platform, game_purchase: game_purchase, platform: platform) }

    it 'GamePlatform should be deleted when platform is deleted' do
      game_with_platform
      expect { platform.destroy }.to change(GamePlatform, :count).by(-1)
    end

    it 'Game should not be deleted when platform is deleted' do
      game_with_platform
      expect { platform.destroy }.not_to change(Game, :count)
    end

    it 'Game purchase platform should be deleted when platform is deleted' do
      game_purchase_platform
      expect { platform.destroy }.to change(GamePurchasePlatform, :count).by(-1)
    end
  end
end
