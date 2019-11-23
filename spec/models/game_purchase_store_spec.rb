# typed: false
require 'rails_helper'

RSpec.describe GamePurchaseStore, type: :model do
  subject(:game_purchase_store) { build(:game_purchase_store) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase_store).to be_valid
    end

    it { should validate_uniqueness_of(:game_purchase_id).scoped_to(:store_id) }
  end

  describe "Associations" do
    it { should belong_to(:game_purchase) }
    it { should belong_to(:store) }
  end

  describe "Indexes" do
    it { should have_db_index([:game_purchase_id, :store_id]).unique }
  end

  describe 'Destructions' do
    let(:game_purchase) { create(:game_purchase) }
    let(:store) { create(:store) }
    let(:game_purchase_store) { create(:game_purchase_store, game_purchase: game_purchase, store: store) }

    it 'GamePurchase should not be deleted when game purchase store is deleted' do
      game_purchase_store
      expect { game_purchase_store.destroy }.to change(GamePurchase, :count).by(0)
    end

    it 'Store should not be deleted when game purchase store is deleted' do
      game_purchase_store
      expect { game_purchase_store.destroy }.to change(Store, :count).by(0)
    end
  end
end
