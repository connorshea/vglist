# typed: false
require 'rails_helper'

RSpec.describe "Merge Games Mutation API", type: :request do
  describe "Mutation merges one game into another" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation ($gameToKeepId: ID!, $gameToMergeId: ID!) {
          mergeGames(gameToKeepId: $gameToKeepId, gameToMergeId: $gameToMergeId) {
            game {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:game1) { create(:game) }
      let(:game2) { create(:game) }

      it "decreases the number of games" do
        game1
        game2

        expect do
          api_request(query_string, variables: { game_to_keep_id: game1.id, game_to_merge_id: game2.id }, token: access_token)
        end.to change(Game, :count).by(-1)
      end

      it "returns data about newly-merged game" do
        result = api_request(query_string, variables: { game_to_keep_id: game1.id, game_to_merge_id: game2.id }, token: access_token)

        expect(result.graphql_dig(:merge_games, :game)).to eq(
          {
            id: game1.id.to_s,
            name: game1.name
          }
        )
      end
    end
  end
end
