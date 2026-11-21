# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "FavoriteGame Mutation API", type: :request do
  describe "Mutation creates a new favorite game" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }
    let(:game) { create(:game) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          favoriteGame(gameId: $id) {
            game {
              id
              name
              isFavorited
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
          name: game.name,
          isFavorited: true
        }
      )
    end

    context 'when there is no current user' do
      it "does not create a FavoriteGame record" do
        game

        expect do
          result = api_request(query_string, variables: { id: game.id }, token: nil)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to favorite this game.")
        end.not_to change(FavoriteGame, :count)
      end
    end
  end
end
