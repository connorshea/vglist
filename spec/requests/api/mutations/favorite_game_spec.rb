# typed: false
require 'rails_helper'

RSpec.describe "FavoriteGame Mutation API", type: :request do
  describe "Mutation creates a new favorite game" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          favoriteGame(input: { gameId: $id }) {
            game {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    it "creates a new FavoriteGame record" do
      sign_in(user)
      game

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: game.id }
        )
      end.to change(FavoriteGame, :count).by(1)
    end

    it "returns basic data for game after favoriting it" do
      sign_in(user)
      game

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )

      expect(result.to_h["data"]["favoriteGame"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end
  end
end
