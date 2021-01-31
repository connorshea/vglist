# typed: false
require 'rails_helper'

RSpec.describe "GamePurchase API", type: :request do
  describe "Query for data on game_purchase" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game_purchase) { create(:game_purchase_with_comments_and_rating) }

    it "returns basic data for game_purchase" do
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

      result = api_request(query_string, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:gamePurchase)).to eq(
        {
          id: game_purchase.id.to_s,
          rating: game_purchase.rating,
          comments: game_purchase.comments
        }
      )
    end
  end

  describe "Query for data on game_purchase owned by private user" do
    let(:user) { create(:confirmed_user) }
    let(:private_user) { create(:private_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game_purchase) { create(:game_purchase_with_comments_and_rating, user: private_user) }

    it "returns null data" do
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

      result = api_request(query_string, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:gamePurchase)).to eq(nil)
    end
  end
end
