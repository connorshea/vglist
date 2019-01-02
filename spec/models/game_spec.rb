require 'rails_helper'

RSpec.describe Game, type: :model do
  subject(:game) { FactoryBot.create(:game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game).to be_valid
    end

    it { should validate_presence_of(:name).on(:create) }

    it { should validate_length_of(:name).is_at_most(120).on(:create) }
    it { should validate_length_of(:description).is_at_most(1000).on(:create) }
  end

  describe "Associations" do
    it { should have_many(:releases) }
    it { should have_many(:platforms) }
  end
end
