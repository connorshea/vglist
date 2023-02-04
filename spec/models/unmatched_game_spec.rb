# typed: false
require 'rails_helper'

RSpec.describe UnmatchedGame, type: :model do
  subject(:unmatched_game) { build(:unmatched_game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(unmatched_game).to be_valid
    end

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(120) }

    it { should validate_presence_of(:external_service_id) }
    it { should validate_presence_of(:external_service_name) }

    it { should validate_inclusion_of(:external_service_name).in_array(['Steam']) }
  end

  describe "Associations" do
    it { should belong_to(:user).optional }
  end
end
