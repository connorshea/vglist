# typed: false
require 'rails_helper'

RSpec.describe GamePurchaseEvent, type: :model do
  subject(:game_purchase_event) { FactoryBot.create(:game_purchase_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase_event).to be_valid
    end

    it 'has an event type enum' do
      expect(game_purchase_event).to define_enum_for(:event_type)
        .with_values([:add_to_library, :change_completion_status])
    end
  end

  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:game_purchase) }
  end
end
