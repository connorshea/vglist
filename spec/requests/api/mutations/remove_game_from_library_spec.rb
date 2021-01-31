# typed: false
require 'rails_helper'

RSpec.describe "RemoveGameFromLibrary Mutation API", type: :request do
  describe "Mutation removes a game from user's library" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
    let(:user2) { create(:confirmed_user) }
    let(:game_purchase_for_other_user) { create(:game_purchase, user: user2, game: game) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
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
    let(:query_string2) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeGameFromLibrary(gamePurchaseId: $id) {
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

      expect(result.graphql_dig(:remove_game_from_library, :game)).to eq(
        {
          id: game.id.to_s,
          name: game.name
        }
      )
    end

    it "returns basic data for game after removing game purchase from the user library" do
      game_purchase

      result = api_request(query_string2, variables: { id: game_purchase.id }, token: access_token)

      expect(result.graphql_dig(:remove_game_from_library, :game)).to eq(
        {
          id: game_purchase.game.id.to_s,
          name: game_purchase.game.name
        }
      )
    end

    it "does not remove the game if the user doesn't own the game purchase when passed a game purchase ID" do
      game_purchase_for_other_user

      expect do
        response = api_request(query_string2, variables: { id: game_purchase_for_other_user.id }, token: access_token)
        expect(response.to_h['errors'].first['message']).to eq("You aren't allowed to delete this game purchase.")
      end.to change(GamePurchase, :count).by(0)
    end
  end
end
