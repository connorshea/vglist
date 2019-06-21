# typed: false
require 'rails_helper'

RSpec.describe GamePlatform, type: :model do
  subject(:game_platform) { FactoryBot.create(:game_platform) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_platform).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:platform_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:platform) }
  end

  describe "Indexes" do
    it { should have_db_index([:game_id, :platform_id]).unique }
  end

  describe 'Destructions' do
    let(:platform) { create(:platform) }
    let(:game) { create(:game) }
    let(:game_platform) { create(:game_platform, platform: platform, game: game) }

    it 'Game should not be deleted when GamePlatform is deleted' do
      game_platform
      expect { game_platform.destroy }.to change(Game, :count).by(0)
    end

    it 'Platform should not be deleted when GamePlatform is deleted' do
      game_platform
      expect { game_platform.destroy }.to change(Platform, :count).by(0)
    end
  end
end
