# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GamePlatform, type: :model do
  subject(:game_platform) { build(:game_platform) }

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
      expect { game_platform.destroy }.not_to change(Game, :count)
    end

    it 'Platform should not be deleted when GamePlatform is deleted' do
      game_platform
      expect { game_platform.destroy }.not_to change(Platform, :count)
    end
  end

  # Copied by database triggers so that a platform's games can be sorted by release
  # date from an index on this table. See ResourceGameSort.
  describe "Release date" do
    let(:game) { create(:game, release_date: Date.new(2010, 5, 1)) }
    let!(:game_platform) { create(:game_platform, game: game) }

    it "is copied from the game when created" do
      expect(game_platform.reload.release_date).to eq(Date.new(2010, 5, 1))
    end

    it "follows the game's release date when it changes" do
      game.update!(release_date: Date.new(2012, 3, 4))
      expect(game_platform.reload.release_date).to eq(Date.new(2012, 3, 4))

      game.update!(release_date: nil)
      expect(game_platform.reload.release_date).to be_nil
    end

    it "follows the game when the row moves to another game" do
      other_game = create(:game, release_date: Date.new(1999, 1, 1))
      game_platform.update!(game: other_game)
      expect(game_platform.reload.release_date).to eq(Date.new(1999, 1, 1))
    end

    it "can't be set to something other than the game's release date" do
      game_platform.update_column(:release_date, Date.new(1980, 1, 1)) # rubocop:disable Rails/SkipsModelValidations
      expect(game_platform.reload.release_date).to eq(Date.new(2010, 5, 1))
    end
  end
end
