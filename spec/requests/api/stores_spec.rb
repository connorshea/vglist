# typed: false
require 'rails_helper'

RSpec.describe "Stores API", type: :request do
  describe "Query for data on stores" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:store) { create(:store) }
    let(:store2) { create(:store) }

    it "returns basic data for store" do
      store
      query_string = <<-GRAPHQL
        query($id: ID!) {
          store(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: store.id }, token: access_token)

      expect(result.graphql_dig(:store)).to eq(
        {
          id: store.id.to_s,
          name: store.name
        }
      )
    end

    it "returns data for a store when searching" do
      store
      query_string = <<-GRAPHQL
        query($query: String!) {
          storeSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: store.name }, token: access_token)

      expect(result.graphql_dig(:store_search, :nodes)).to eq(
        [{
          id: store.id.to_s,
          name: store.name
        }]
      )
    end

    it "returns data for stores when listing" do
      store
      store2
      query_string = <<-GRAPHQL
        query {
          stores {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:stores, :nodes)).to eq(
        [
          {
            id: store.id.to_s,
            name: store.name
          },
          {
            id: store2.id.to_s,
            name: store2.name
          }
        ]
      )
    end
  end
end
