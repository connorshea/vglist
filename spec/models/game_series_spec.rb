require 'rails_helper'

RSpec.describe GameSeries, type: :model do
  subject(:game_series) { FactoryBot.create(:game_series) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_series).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:series_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:series) }
  end
end
