# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with basic games query' do
      let!(:game) { create(:game) }
      let!(:game2) { create(:game) }

      it "returns data for games when listing" do
        query_string = <<-GRAPHQL
          query {
            games {
              nodes {
                id
                name
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        expect(result.graphql_dig(:games, :nodes)).to eq(
          [
            {
              id: game.id.to_s,
              name: game.name
            },
            {
              id: game2.id.to_s,
              name: game2.name
            }
          ]
        )
      end
    end

    context 'when sorting games' do
      let(:games) { create_list(:game, 3) }

      # Test each sort order and make sure it matches the corresponding sort
      # method. We test the sort scopes individually in method specs, so we
      # should be able to rely on those tests for testing the specific order.
      [:newest, :oldest, :recently_updated, :least_recently_updated, :most_favorites, :most_owners, :recently_released, :highest_avg_rating].each do |sort_order|
        it "returns data in expected order for #{sort_order}" do
          query_string = <<-GRAPHQL_WITH_INTERP
            query {
              games(sortBy: #{sort_order.upcase}) {
                nodes {
                  id
                  name
                }
              }
            }
          GRAPHQL_WITH_INTERP

          games
          result = api_request(query_string, token: access_token)
          # This is a bit of a hack to get the games in the same format as
          # they're returned by GraphQL (hashes with only the specific
          # requested keys, with IDs being strings).
          expected_games = Game.public_send(sort_order).select(:id, :name).map(&:as_json).map(&:symbolize_keys).map do |game|
            game[:id] = game[:id].to_s
            game
          end

          expect(result.graphql_dig(:games, :nodes)).to eq(expected_games)
        end
      end
    end
  end
end
