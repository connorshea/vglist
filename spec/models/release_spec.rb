require 'rails_helper'

RSpec.describe Release, type: :model do
  subject(:release) { FactoryBot.create(:release) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(release).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:platform) }
    it { should have_many(:release_purchases) }
    it { should have_many(:purchasers) }
  end
end
