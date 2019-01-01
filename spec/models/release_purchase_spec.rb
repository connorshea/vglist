require 'rails_helper'

RSpec.describe ReleasePurchase, type: :model do
  subject { FactoryBot.create(:release_purchase) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_length_of(:comment).is_at_most(500).on(:create) }
  end

  describe "Associations" do
    it { should belong_to(:release) }
    it { should belong_to(:user) }
  end
end
