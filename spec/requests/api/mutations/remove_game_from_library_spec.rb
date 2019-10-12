# typed: false
require 'rails_helper'

RSpec.describe "RemoveGameFromLibrary Mutation API", type: :request do
  describe "Mutation removes a game from user's library" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
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
      sign_in(user)
      game_purchase

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: game.id }
        )
      end.to change(GamePurchase, :count).by(-1)
    end

    it "returns basic data for game after removing it from the user library" do
      sign_in(user)
      game_purchase

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )

      expect(result.to_h["data"]["removeGameFromLibrary"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end
  end
end
