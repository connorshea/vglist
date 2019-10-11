# typed: false
require 'rails_helper'

RSpec.describe "GamePurchase API", type: :request do
  describe "Query for data on game_purchase" do
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase_with_comments_and_rating) }

    it "returns basic data for game_purchase" do
      sign_in(user)
      game_purchase
      query_string = <<-GRAPHQL
        query($id: ID!) {
          gamePurchase(id: $id) {
            id
            rating
            comments
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game_purchase.id }
      )
      expect(result.to_h["data"]["gamePurchase"]).to eq(
        {
          "id" => game_purchase.id.to_s,
          "rating" => game_purchase.rating,
          "comments" => game_purchase.comments
        }
      )
    end
  end

  describe "Query for data on game_purchase owned by private user" do
    let(:user) { create(:confirmed_user) }
    let(:private_user) { create(:private_user) }
    let(:game_purchase) { create(:game_purchase_with_comments_and_rating, user: private_user) }

    it "returns null data" do
      sign_in(user)
      game_purchase
      query_string = <<-GRAPHQL
        query($id: ID!) {
          gamePurchase(id: $id) {
            id
            rating
            comments
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game_purchase.id }
      )
      expect(result.to_h["data"]["gamePurchase"]).to eq(nil)
    end
  end
end
