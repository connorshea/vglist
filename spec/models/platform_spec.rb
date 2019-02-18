require 'rails_helper'

RSpec.describe Platform, type: :model do
  subject(:platform) { FactoryBot.create(:platform) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(platform).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "Associations" do
    it { should have_many(:game_platforms) }
    it { should have_many(:games) }
  end
end
