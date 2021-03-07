# typed: false
require 'rails_helper'

RSpec.describe "AddGameToLibrary Mutation API", type: :request do
  describe "Mutation creates a new GamePurchase" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          addGameToLibrary(gameId: $id) {
            gamePurchase {
              user {
                id
              }
              game {
                name
              }
              hoursPlayed
              comments
              completionStatus
              rating
            }
          }
        }
      GRAPHQL
    end

    it "creates a new GamePurchase record" do
      game

      expect do
        api_request(query_string, variables: { id: game.id }, token: access_token)
      end.to change(GamePurchase, :count).by(1)
    end

    it "returns basic data for game purchase after adding it to user's library" do
      game

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:add_game_to_library, :game_purchase)).to eq(
        {
          user: {
            id: user.id.to_s
          },
          game: {
            name: game.name
          },
          hoursPlayed: nil,
          comments: "",
          completionStatus: nil,
          rating: nil
        }
      )
    end
  end

  describe "Mutation creates a new GamePurchase with full data" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          addGameToLibrary(
            gameId: $id,
            hoursPlayed: 10,
            comments: "Pretty good",
            completionStatus: NOT_APPLICABLE,
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
              comments
              completionStatus
              rating
              startDate
              completionDate
            }
          }
        }
      GRAPHQL
    end

    it "creates a new GamePurchase record with all fields filled" do
      game

      expect do
        api_request(query_string, variables: { id: game.id }, token: access_token)
      end.to change(GamePurchase, :count).by(1)
    end

    it "returns data for game purchase after adding it to user's library" do
      game

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:add_game_to_library, :game_purchase)).to eq(
        {
          user: {
            id: user.id.to_s
          },
          game: {
            name: game.name
          },
          hoursPlayed: 10,
          comments: "Pretty good",
          completionStatus: "NOT_APPLICABLE",
          rating: 100,
          startDate: "2019-10-10",
          completionDate: "2019-10-11"
        }
      )
    end
  end
end
