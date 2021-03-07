# typed: false
require 'rails_helper'

RSpec.describe "UnfavoriteGame Mutation API", type: :request do
  describe "Mutation unfavorites a game" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:favorite_game) { create(:favorite_game, user: user, game: game) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          unfavoriteGame(gameId: $id) {
            game {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    it "unfavorites a game" do
      favorite_game

      expect do
        api_request(query_string, variables: { id: game.id }, token: access_token)
      end.to change(FavoriteGame, :count).by(-1)
    end

    it "returns basic data for game after unfavoriting it" do
      favorite_game

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:unfavorite_game, :game)).to eq(
        {
          id: game.id.to_s,
          name: game.name
        }
      )
    end
  end
end
