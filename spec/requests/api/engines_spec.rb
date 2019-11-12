# typed: false
require 'rails_helper'

RSpec.describe "Engines API", type: :request do
  describe "Query for data on engines" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:engine) { create(:engine) }
    let(:engine2) { create(:engine) }

    it "returns basic data for engine" do
      engine
      query_string = <<-GRAPHQL
        query($id: ID!) {
          engine(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: engine.id }, token: access_token)

      expect(result["data"]["engine"]).to eq(
        {
          "id" => engine.id.to_s,
          "name" => engine.name
        }
      )
    end

    it "returns data for a engine when searching" do
      engine
      query_string = <<-GRAPHQL
        query($query: String!) {
          engineSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: engine.name }, token: access_token)

      expect(result["data"]["engineSearch"]["nodes"]).to eq(
        [{
          "id" => engine.id.to_s,
          "name" => engine.name
        }]
      )
    end

    it "returns data for engines when listing" do
      engine
      engine2
      query_string = <<-GRAPHQL
        query {
          engines {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.to_h["data"]["engines"]["nodes"]).to eq(
        [
          {
            "id" => engine.id.to_s,
            "name" => engine.name
          },
          {
            "id" => engine2.id.to_s,
            "name" => engine2.name
          }
        ]
      )
    end
  end
end
