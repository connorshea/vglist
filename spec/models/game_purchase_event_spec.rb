# typed: false
require 'rails_helper'

RSpec.describe GamePurchaseEvent, type: :model do
  subject(:game_purchase_event) { FactoryBot.create(:game_purchase_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase_event).to be_valid
    end

    it { should validate_presence_of(:event_type) }

    it 'has an event type enum' do
      expect(game_purchase_event).to define_enum_for(:event_type)
        .with_values([:add_to_library, :change_completion_status])
    end
  end

  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:game_purchase) }
  end

  describe 'Destructions' do
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase) }
    let(:game_purchase_event) { create(:game_purchase_event, user: user, game_purchase: game_purchase) }

    it 'GamePurchase should not be deleted when GamePurchaseEvent is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(GamePurchase, :count).by(0)
    end

    it 'User should not be deleted when GamePurchaseEvent is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(User, :count).by(0)
    end

    it 'Game should not be deleted when GamePurchaseEvent is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(Game, :count).by(0)
    end

    it 'GamePurchaseEvent should be deleted when GamePurchase is deleted' do
      game_purchase
      expect { game_purchase.destroy }.to change(GamePurchaseEvent, :count).by(-1)
    end

    it 'GamePurchaseEvent should be deleted when User is deleted' do
      game_purchase_event
      expect { user.destroy }.to change(GamePurchaseEvent, :count).by(-1)
    end
  end
end
