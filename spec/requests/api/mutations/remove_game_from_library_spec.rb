# typed: false
require 'rails_helper'

RSpec.describe "RemoveGameFromLibrary Mutation API", type: :request do
  describe "Mutation removes a game from user's library" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeGameFromLibrary(gameId: $id) {
            game {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    it "deletes the game purchase" do
      game_purchase

      expect do
        api_request(query_string, variables: { id: game.id }, token: access_token)
      end.to change(GamePurchase, :count).by(-1)
    end

    it "returns basic data for game after removing it from the user library" do
      game_purchase

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result["data"]["removeGameFromLibrary"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end
  end
end
