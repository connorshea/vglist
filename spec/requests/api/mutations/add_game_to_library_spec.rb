# typed: false
require 'rails_helper'

RSpec.describe "AddGameToLibrary Mutation API", type: :request do
  describe "Mutation creates a new GamePurchase" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
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
      sign_in(user)
      game

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: game.id }
        )
      end.to change(GamePurchase, :count).by(1)
    end

    it "returns basic data for game purchase after adding it to user's library" do
      sign_in(user)
      game

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )

      expect(result.to_h["data"]["addGameToLibrary"]["gamePurchase"]).to eq(
        {
          "user" => {
            "id" => user.id.to_s
          },
          "game" => {
            "name" => game.name
          },
          "hoursPlayed" => nil,
          "comments" => "",
          "completionStatus" => nil,
          "rating" => nil
        }
      )
    end
  end

  describe "Mutation creates a new GamePurchase with full data" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          addGameToLibrary(
            gameId: $id,
            hoursPlayed: 10,
            comments: "Pretty good",
            completionStatus: NOT_APPLICABLE,
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
              comments
              completionStatus
              rating
            }
          }
        }
      GRAPHQL
    end

    it "creates a new GamePurchase record with all fields filled" do
      sign_in(user)
      game

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: game.id }
        )
      end.to change(GamePurchase, :count).by(1)
    end

    it "returns data for game purchase after adding it to user's library" do
      sign_in(user)
      game

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )

      expect(result.to_h["data"]["addGameToLibrary"]["gamePurchase"]).to eq(
        {
          "user" => {
            "id" => user.id.to_s
          },
          "game" => {
            "name" => game.name
          },
          "hoursPlayed" => 10,
          "comments" => "Pretty good",
          "completionStatus" => "NOT_APPLICABLE",
          "rating" => 100
        }
      )
    end
  end
end
