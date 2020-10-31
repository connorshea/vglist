# typed: false
require 'rails_helper'

RSpec.describe SteamAppId, type: :model do
  subject(:steam_app_id) { build(:steam_app_id) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(steam_app_id).to be_valid
    end

    it { should validate_uniqueness_of(:app_id) }
    it 'validates numericality of app_id' do
      expect(steam_app_id).to validate_numericality_of(:app_id)
        .only_integer
        .is_greater_than(0)
    end
  end

  describe 'Custom Validations' do
    let!(:steam_blocklist) { create(:steam_blocklist, steam_app_id: 420) }
    let!(:steam_app_id) { build(:steam_app_id, app_id: 420) }

    it 'fails validation if Steam App ID is blocklisted' do
      steam_blocklist
      expect(steam_app_id).to be_invalid
      expect(steam_app_id.errors[:app_id]).to include('is blocklisted')
    end
  end

  describe "Associations" do
    it { should belong_to(:game) }
  end

  describe "Indexes" do
    it { should have_db_index(:app_id).unique }
  end

  describe 'Destructions' do
    let(:game) { create(:game) }
    let(:steam_app_id) { create(:steam_app_id, game: game) }

    it 'Steam App ID should be deleted when game is deleted' do
      steam_app_id
      expect { game.destroy }.to change(SteamAppId, :count).by(-1)
    end
  end
end
