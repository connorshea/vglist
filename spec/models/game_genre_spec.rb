require 'rails_helper'

RSpec.describe GameGenre, type: :model do
  subject(:game_genre) { FactoryBot.create(:game_genre) }

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
      expect { game_genre.destroy }.to change(Game, :count).by(0)
    end

    it 'Genre should not be deleted when GameGenre is deleted' do
      game_genre
      expect { game_genre.destroy }.to change(Genre, :count).by(0)
    end
  end
end
