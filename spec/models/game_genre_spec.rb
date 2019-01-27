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
end
