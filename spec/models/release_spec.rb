require 'rails_helper'

RSpec.describe Release, type: :model do
  subject { FactoryBot.create(:release) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:name).on(:create) }

    it { should validate_length_of(:name).is_at_most(120).on(:create) }
    it { should validate_length_of(:description).is_at_most(1000).on(:create) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:platform) }
    it { should have_many(:release_purchases) }
    it { should have_many(:purchasers) }
  end
end
