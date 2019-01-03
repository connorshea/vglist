require 'rails_helper'

RSpec.describe Genre, type: :model do
  subject(:genre) { FactoryBot.create(:genre) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(genre).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "Associations" do
    it { should have_and_belong_to_many(:games) }
  end
end
