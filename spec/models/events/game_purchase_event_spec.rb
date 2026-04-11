# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::GamePurchaseEvent, type: :model do
  subject(:game_purchase_event) { build(:game_purchase_library_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase_event).to be_valid
    end

    it { should validate_presence_of(:event_category) }
  end

  describe "Associations" do
    it { should belong_to(:eventable).class_name('GamePurchase') }
    it { should belong_to(:user) }
  end

  describe "Enums" do
    it 'has an event_category enum' do
      expect(game_purchase_event).to define_enum_for(:event_category)
        .with_values(add_to_library: 0, change_completion_status: 1)
    end
  end
end
