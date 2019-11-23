# typed: false
require 'rails_helper'

RSpec.describe Store, type: :model do
  subject(:store) { build(:store) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(store).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
  end

  describe "Associations" do
    it { should have_many(:game_purchase_stores) }
    it { should have_many(:game_purchases).through(:game_purchase_stores).source(:game_purchase) }
  end

  describe 'Destructions' do
    let(:store) { create(:store) }
    let(:game_purchase) { create(:game_purchase) }
    let(:game_purchase_store) { create(:game_purchase_store, game_purchase: game_purchase, store: store) }

    it 'Game purchase store should be deleted when store is deleted' do
      game_purchase_store
      expect { store.destroy }.to change(GamePurchaseStore, :count).by(-1)
    end
  end
end
