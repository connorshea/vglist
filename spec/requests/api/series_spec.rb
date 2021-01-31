# typed: false
require 'rails_helper'

RSpec.describe "Series API", type: :request do
  describe "Query for data on series" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:series) { create(:series) }
    let(:series2) { create(:series) }

    it "returns basic data for series" do
      series
      query_string = <<-GRAPHQL
        query($id: ID!) {
          series(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: series.id }, token: access_token)

      expect(result.graphql_dig(:series)).to eq(
        {
          id: series.id.to_s,
          name: series.name
        }
      )
    end

    it "returns data for a series when searching" do
      series
      query_string = <<-GRAPHQL
        query($query: String!) {
          seriesSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: series.name }, token: access_token)

      expect(result.graphql_dig(:series_search, :nodes)).to eq(
        [{
          id: series.id.to_s,
          name: series.name
        }]
      )
    end

    it "returns data for series' when listing" do
      series
      series2
      query_string = <<-GRAPHQL
        query {
          seriesList {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:series_list, :nodes)).to eq(
        [
          {
            id: series.id.to_s,
            name: series.name
          },
          {
            id: series2.id.to_s,
            name: series2.name
          }
        ]
      )
    end
  end
end
