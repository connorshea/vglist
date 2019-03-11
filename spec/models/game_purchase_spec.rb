require 'rails_helper'

RSpec.describe GamePurchase, type: :model do
  subject(:game_purchase) { FactoryBot.create(:game_purchase) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase).to be_valid
    end

    it { should validate_length_of(:comments).is_at_most(500) }
    it { should validate_uniqueness_of(:game_id).scoped_to(:user_id) }
    it 'validates the rating' do
      expect(game_purchase).to validate_numericality_of(:rating)
        .only_integer
        .allow_nil
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    end
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:user) }
  end
end
