# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameGenre, type: :model do
  subject(:game_genre) { build(:game_genre) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_genre).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:genre_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:genre) }
  end

  describe "Indexes" do
    it { should have_db_index([:game_id, :genre_id]).unique }
  end

  describe 'Destructions' do
    let(:genre) { create(:genre) }
    let(:game) { create(:game) }
    let(:game_genre) { create(:game_genre, genre: genre, game: game) }

    it 'Game should not be deleted when GameGenre is deleted' do
      game_genre
      expect { game_genre.destroy }.not_to change(Game, :count)
    end

    it 'Genre should not be deleted when GameGenre is deleted' do
      game_genre
      expect { game_genre.destroy }.not_to change(Genre, :count)
    end
  end

  # Copied by database triggers so that a genre's games can be sorted by release
  # date from an index on this table. See ResourceGameSort.
  describe "Release date" do
    let(:game) { create(:game, release_date: Date.new(2010, 5, 1)) }
    let!(:game_genre) { create(:game_genre, game: game) }

    it "is copied from the game when created" do
      expect(game_genre.reload.release_date).to eq(Date.new(2010, 5, 1))
    end

    it "follows the game's release date when it changes" do
      game.update!(release_date: Date.new(2012, 3, 4))
      expect(game_genre.reload.release_date).to eq(Date.new(2012, 3, 4))

      game.update!(release_date: nil)
      expect(game_genre.reload.release_date).to be_nil
    end

    it "follows the game when the row moves to another game" do
      other_game = create(:game, release_date: Date.new(1999, 1, 1))
      game_genre.update!(game: other_game)
      expect(game_genre.reload.release_date).to eq(Date.new(1999, 1, 1))
    end

    it "can't be set to something other than the game's release date" do
      game_genre.update_column(:release_date, Date.new(1980, 1, 1)) # rubocop:disable Rails/SkipsModelValidations
      expect(game_genre.reload.release_date).to eq(Date.new(2010, 5, 1))
    end
  end
end
