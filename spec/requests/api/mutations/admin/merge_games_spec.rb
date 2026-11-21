# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Merge Games Mutation API", type: :request do
  describe "Mutation merges one game into another" do
    let(:access_token) { JwtService.encode(user) }
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

    [:moderator, :user].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }
        let!(:game1) { create(:game) }
        let!(:game2) { create(:game) }

        it "does not merge the games", :aggregate_failures do
          expect do
            result = api_request(query_string, variables: { game_to_keep_id: game1.id, game_to_merge_id: game2.id }, token: access_token)
            expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to merge these games.")
          end.not_to change(Game, :count)
          expect(Game.exists?(game2.id)).to be(true)
        end
      end
    end

    context 'when there is no current user' do
      let!(:game1) { create(:game) }
      let!(:game2) { create(:game) }

      it "does not merge the games" do
        expect do
          result = api_request(query_string, variables: { game_to_keep_id: game1.id, game_to_merge_id: game2.id }, token: nil)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to merge these games.")
        end.not_to change(Game, :count)
      end
    end
  end
end
