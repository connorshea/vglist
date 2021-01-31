# typed: false
require 'rails_helper'

RSpec.describe "UpdateGameInLibrary Mutation API", type: :request do
  describe "Mutation updates an existing GamePurchase" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase_for_other_user) { create(:game_purchase, game: game, user: user2) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(gamePurchaseId: $id, hoursPlayed: 5) {
            gamePurchase {
              user {
                id
              }
              game {
                name
              }
              hoursPlayed
            }
          }
        }
      GRAPHQL
    end

    it "updates a GamePurchase record owned by the user" do
      game_purchase

      result = api_request(query_string, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:updateGameInLibrary, :gamePurchase)).to eq(
        {
          user: {
            id: user.id.to_s
          },
          game: {
            name: game.name
          },
          hoursPlayed: 5
        }
      )
    end

    it "does not update the game purchase if the current user does not own it" do
      game_purchase_for_other_user

      expect do
        response = api_request(query_string, variables: { id: game_purchase_for_other_user.id }, token: access_token)
        expect(response.to_h['errors'].first['message']).to eq("You aren't allowed to update this game purchase.")
      end.to change(GamePurchase, :count).by(0)
    end
  end

  describe "Mutation updates an existing GamePurchase with more data" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase2) { create(:game_purchase, game: game, user: user, hours_played: 5, rating: 1) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(
            gamePurchaseId: $id,
            hoursPlayed: 5,
            completionStatus: UNPLAYED,
            comments: "Pretty good",
            rating: 100,
            startDate: "2019-10-10",
            completionDate: "2019-10-11"
          ) {
            gamePurchase {
              user {
                id
              }
              game {
                name
              }
              hoursPlayed
              completionStatus
              comments
              rating
              startDate
              completionDate
            }
          }
        }
      GRAPHQL
    end
    let(:query_string2) do
      <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(
            gamePurchaseId: $id,
            hoursPlayed: null,
            rating: 100
          ) {
            gamePurchase {
              user {
                id
              }
              game {
                name
              }
              hoursPlayed
              rating
            }
          }
        }
      GRAPHQL
    end

    it "updates more fields in a GamePurchase record" do
      game_purchase

      result = api_request(query_string, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:updateGameInLibrary, :gamePurchase)).to eq(
        {
          user: {
            id: user.id.to_s
          },
          game: {
            name: game.name
          },
          hoursPlayed: 5,
          completionStatus: "UNPLAYED",
          comments: "Pretty good",
          rating: 100,
          startDate: "2019-10-10",
          completionDate: "2019-10-11"
        }
      )
    end

    it "correctly overrides other data" do
      game_purchase2

      result = api_request(query_string2, variables: { id: game_purchase2.id }, token: access_token)

      expect(result.graphql_dig(:updateGameInLibrary, :gamePurchase)).to eq(
        {
          user: {
            id: user.id.to_s
          },
          game: {
            name: game.name
          },
          hoursPlayed: nil,
          rating: 100
        }
      )
    end
  end
end
