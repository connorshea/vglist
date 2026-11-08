# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "UpdateGameInLibrary Mutation API", type: :request do
  describe "Mutation updates an existing GamePurchase" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase_for_other_user) { create(:game_purchase, game: game, user: user2) }
    let(:access_token) { JwtService.encode(user) }
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

      expect(result.graphql_dig(:update_game_in_library, :game_purchase)).to eq(
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
      end.not_to change(GamePurchase, :count)
    end

    it "returns the same error for a game purchase that doesn't exist" do
      response = api_request(query_string, variables: { id: GamePurchase.maximum(:id).to_i + 1 }, token: access_token)

      expect(response.to_h['errors'].first['message']).to eq("You aren't allowed to update this game purchase.")
    end
  end

  describe "Mutation updates an existing GamePurchase with more data" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase2) { create(:game_purchase, game: game, user: user, hours_played: 5, rating: 1) }
    let(:access_token) { JwtService.encode(user) }
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

      expect(result.graphql_dig(:update_game_in_library, :game_purchase)).to eq(
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

    it "clears the comments when they are sent as null" do
      game_purchase = create(:game_purchase, game: game, user: user, comments: "Pretty good")
      query = <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(gamePurchaseId: $id, completionStatus: COMPLETED, comments: null) {
            gamePurchase {
              completionStatus
              comments
            }
          }
        }
      GRAPHQL

      result = api_request(query, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:update_game_in_library, :game_purchase)).to eq(
        {
          completionStatus: "COMPLETED",
          comments: ""
        }
      )
    end

    it "resets the replay count to zero when it is sent as null" do
      game_purchase = create(:game_purchase, game: game, user: user, replay_count: 3)
      query = <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(gamePurchaseId: $id, replayCount: null) {
            gamePurchase {
              replayCount
            }
          }
        }
      GRAPHQL

      result = api_request(query, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:update_game_in_library, :game_purchase)).to eq({ replayCount: 0 })
    end

    it "returns a validation error for hours played past the column limit" do
      game_purchase
      query = <<-GRAPHQL
        mutation($id: ID!) {
          updateGameInLibrary(gamePurchaseId: $id, hoursPlayed: 1000000000) {
            gamePurchase {
              hoursPlayed
            }
          }
        }
      GRAPHQL

      result = api_request(query, variables: { id: game_purchase.id }, token: access_token)

      expect(result.to_h['errors'].first['message']).to eq("Hours played must be less than or equal to 999999999.9")
    end

    it "correctly overrides other data" do
      game_purchase2

      result = api_request(query_string2, variables: { id: game_purchase2.id }, token: access_token)

      expect(result.graphql_dig(:update_game_in_library, :game_purchase)).to eq(
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
