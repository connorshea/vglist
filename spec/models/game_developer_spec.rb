require 'rails_helper'

RSpec.describe GameDeveloper, type: :model do
  subject(:game_developer) { FactoryBot.create(:game_developer) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_developer).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:company_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:company) }
  end
end
