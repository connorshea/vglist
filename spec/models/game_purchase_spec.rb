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

    it 'validates the hours_played' do
      expect(game_purchase).to validate_numericality_of(:hours_played)
        .allow_nil
        .is_greater_than_or_equal_to(0)
    end

    it 'validates the completion status enum' do
      expect(game_purchase).to define_enum_for(:completion_status)
        .with_values(
          [
            :unplayed,
            :in_progress,
            :dropped,
            :completed,
            :fully_completed,
            :not_applicable
          ]
        )
        .backed_by_column_of_type(:integer)
    end
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:user) }
    it { should have_many(:game_purchase_platforms) }
    it { should have_many(:platforms).through(:game_purchase_platforms).source(:platform) }
  end
end
