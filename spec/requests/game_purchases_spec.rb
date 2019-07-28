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

  describe "PUT game_purchase_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game_purchase) { create(:game_purchase, user: user) }
    let(:game_purchase_attributes) { attributes_for(:game_purchase) }

    it "updates game purchase rating" do
      sign_in(user)
      game_purchase_attributes[:rating] = 50
      put game_purchase_path(id: game_purchase.id, format: :json), params: { game_purchase: game_purchase_attributes }
      expect(game_purchase.reload.rating).to be(50)
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
