# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game) { create(:game) }
    let(:game2) { create(:game) }

    it "returns data for games when listing" do
      game
      game2
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
end
