# typed: false
require 'rails_helper'

RSpec.describe "Platforms API", type: :request do
  describe "Query for data on platforms" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id) }
    let(:platform) { create(:platform) }
    let(:platform2) { create(:platform) }

    it "returns basic data for platform" do
      platform
      query_string = <<-GRAPHQL
        query($id: ID!) {
          platform(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: platform.id }, token: access_token)

      expect(result["data"]["platform"]).to eq(
        {
          "id" => platform.id.to_s,
          "name" => platform.name
        }
      )
    end

    it "returns data for a platform when searching" do
      platform
      query_string = <<-GRAPHQL
        query($query: String!) {
          platformSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: platform.name }, token: access_token)

      expect(result["data"]["platformSearch"]["nodes"]).to eq(
        [{
          "id" => platform.id.to_s,
          "name" => platform.name
        }]
      )
    end

    it "returns data for platforms when listing" do
      platform
      platform2
      query_string = <<-GRAPHQL
        query {
          platforms {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result["data"]["platforms"]["nodes"]).to eq(
        [
          {
            "id" => platform.id.to_s,
            "name" => platform.name
          },
          {
            "id" => platform2.id.to_s,
            "name" => platform2.name
          }
        ]
      )
    end
  end
end
