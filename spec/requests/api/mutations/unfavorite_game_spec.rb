# typed: false
require 'rails_helper'

RSpec.describe "UnfavoriteGame Mutation API", type: :request do
  describe "Mutation unfavorites a game" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
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
      sign_in(user)
      favorite_game

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: game.id }
        )
      end.to change(FavoriteGame, :count).by(-1)
    end

    it "returns basic data for game after unfavoriting it" do
      sign_in(user)
      favorite_game

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )

      expect(result.to_h["data"]["unfavoriteGame"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end
  end
end
