require 'rails_helper'

RSpec.describe Game, type: :model do
  subject(:game) { FactoryBot.create(:game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "Associations" do
    it { should have_many(:platforms) }
    it { should have_many(:game_genres) }
    it { should have_many(:game_engines) }
    it { should have_many(:game_purchases) }
    it { should have_many(:purchasers) }
  end
end
