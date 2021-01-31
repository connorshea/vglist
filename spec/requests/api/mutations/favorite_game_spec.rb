# typed: false
require 'rails_helper'

RSpec.describe "FavoriteGame Mutation API", type: :request do
  describe "Mutation creates a new favorite game" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game) { create(:game) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          favoriteGame(gameId: $id) {
            game {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    it "creates a new FavoriteGame record" do
      game

      expect do
        api_request(query_string, variables: { id: game.id }, token: access_token)
      end.to change(FavoriteGame, :count).by(1)
    end

    it "returns basic data for game after favoriting it" do
      game

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:favorite_game, :game)).to eq(
        {
          id: game.id.to_s,
          name: game.name
        }
      )
    end
  end
end
