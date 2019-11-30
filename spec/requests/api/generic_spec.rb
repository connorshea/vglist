# typed: false
require 'rails_helper'

RSpec.describe "API", type: :request do
  describe "Query for data on game_purchase" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:games) { create_list(:game, 31) }

    it "returns correct hasNextPage with 31 records" do
      games
      query_string = <<-GRAPHQL
        query {
          games {
            nodes {
              id
              name
            }
            pageInfo {
              hasNextPage
              pageSize
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result["data"]["games"]["pageInfo"]["hasNextPage"]).to eq(true)
      expect(result["data"]["games"]["pageInfo"]["pageSize"]).to eq(30)
    end
  end
end
