# typed: false
require 'rails_helper'

RSpec.describe "GamePurchases", type: :request do
  describe "GET game_purchases_path" do
    it "returns http success" do
      get game_purchases_path(format: :json)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET game_purchases_path specifying a user id" do
    let!(:user) { create(:user) }
    let!(:game_purchase) { create(:game_purchase, user: user) }
    let(:user2) { create(:user) }

    it "returns http success" do
      get game_purchases_path(format: :json, user_id: user.id)
      expect(response).to have_http_status(:success)
    end

    it "returns the game purchase associated with the user" do
      get game_purchases_path(format: :json, user_id: user.id)
      expect(JSON.parse(response.body).first['id']).to eq(game_purchase.id)
    end

    it "doesn't include any other game purchases" do
      create(:game_purchase, user: user2)
      get game_purchases_path(format: :json, user_id: user.id)
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  describe "GET game_purchase_path" do
    let(:game_purchase) { create(:game_purchase) }

    it "returns http success" do
      get game_purchase_path(id: game_purchase.id, format: :json)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST game_purchases_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase_attributes) { attributes_for(:game_purchase_with_comments_and_rating, user: user) }

    it "creates a new game_purchase" do
      sign_in(user)
      game_purchase_attributes[:user_id] = user.id
      game_purchase_attributes[:game_id] = game.id
      expect do
        post game_purchases_path(format: :json), params: { game_purchase: game_purchase_attributes }
      end.to change(GamePurchase, :count).by(1)
    end
  end

  describe "POST bulk_update_game_purchases_path" do
    let(:user) { create(:confirmed_user) }
    let(:game_purchase1) { create(:game_purchase, user: user, completion_status: :completed) }
    let(:game_purchase2) { create(:game_purchase, user: user, completion_status: :completed) }
    let(:game_purchase_with_store) { create(:game_purchase, user: user, stores: [store3]) }
    let(:store1) { create(:store) }
    let(:store2) { create(:store) }
    let(:store3) { create(:store) }

    it "updates multiple game_purchases to have the same rating" do
      sign_in(user)
      post bulk_update_game_purchases_path(format: :json),
        params: {
          ids: [game_purchase1.id, game_purchase2.id],
          rating: 100
        }
      expect(game_purchase1.reload.rating).to eq(100)
      expect(game_purchase2.reload.rating).to eq(100)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "updates multiple game_purchases to have the same completion status and rating" do
      sign_in(user)
      post bulk_update_game_purchases_path(format: :json),
        params: {
          ids: [game_purchase1.id, game_purchase2.id],
          rating: 100,
          completion_status: :unplayed
        }
      expect(game_purchase1.reload.rating).to eq(100)
      expect(game_purchase2.reload.rating).to eq(100)
      expect(game_purchase1.reload.completion_status).to eq('unplayed')
      expect(game_purchase2.reload.completion_status).to eq('unplayed')
    end

    it "updates game_purchases to have the same rating but doesn't nullify completion status" do
      sign_in(user)
      post bulk_update_game_purchases_path(format: :json),
        params: {
          ids: [game_purchase1.id, game_purchase2.id],
          rating: 100,
          completion_status: nil
        }
      expect(game_purchase1.reload.rating).to eq(100)
      expect(game_purchase2.reload.rating).to eq(100)
      expect(game_purchase1.reload.completion_status).to eq('completed')
      expect(game_purchase2.reload.completion_status).to eq('completed')
    end
    # rubocop:enable RSpec/MultipleExpectations

    it "updates game_purchases to have stores" do
      sign_in(user)
      post bulk_update_game_purchases_path(format: :json),
        params: {
          ids: [game_purchase1.id, game_purchase_with_store.id],
          store_ids: [store1.id, store2.id]
        }
      expect(game_purchase1.reload.store_ids).to eq([store1.id, store2.id])
      # Disregard order of elements.
      expect(game_purchase_with_store.reload.store_ids).to contain_exactly(store1.id, store2.id, store3.id)
    end
  end

  describe "PUT game_purchase_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game_purchase) { create(:game_purchase, user: user) }
    let(:game_purchase_attributes) { attributes_for(:game_purchase) }

    it "updates game purchase rating" do
      sign_in(user)
      game_purchase_attributes[:rating] = 50
      put game_purchase_path(id: game_purchase.id, format: :json), params: { game_purchase: game_purchase_attributes }
      expect(game_purchase.reload.rating).to eq(50)
    end
  end

  describe "DELETE game_purchase_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game_purchase) { create(:game_purchase, user: user) }

    it "deletes a game purchase" do
      sign_in(user)
      expect do
        delete game_purchase_path(id: game_purchase.id)
      end.to change(GamePurchase, :count).by(-1)
    end
  end
end
