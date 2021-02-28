# typed: false
require 'rails_helper'

RSpec.describe "Game Search API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game) { create(:game) }
    let(:game2) { create(:game) }

    it "returns data for a game when searching" do
      query_string = <<-GRAPHQL
        query($query: String!) {
          gameSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: game.name }, token: access_token)

      expect(result.graphql_dig(:game_search, :nodes)).to include_hash_matching(
        id: game.id.to_s,
        name: game.name
      )
    end
  end
end
