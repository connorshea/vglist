# typed: false
require 'rails_helper'

RSpec.describe FavoriteGame, type: :model do
  subject(:favorite_game) { FactoryBot.create(:favorite_game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(favorite_game).to be_valid
    end

    it 'validates uniqueness' do
      expect(favorite_game).to validate_uniqueness_of(:user_id)
        .scoped_to(:game_id)
        .with_message('can only favorite a game once')
    end
  end

  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:game) }
  end

  describe "Indexes" do
    it { should have_db_index(:user_id) }
    it { should have_db_index(:game_id) }
    it { should have_db_index([:user_id, :game_id]).unique }
  end

  describe 'Destructions' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:favorite_game) { create(:favorite_game, user: user, game: game) }

    it 'Game should not be deleted when favorite is deleted' do
      favorite_game
      expect { favorite_game.destroy }.to change(Game, :count).by(0)
    end

    it 'User should not be deleted when favorite is deleted' do
      favorite_game
      expect { favorite_game.destroy }.to change(User, :count).by(0)
    end
  end
end
