# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Platforms API", type: :request do
  describe "Query for data on platforms" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }
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

      expect(result.graphql_dig(:platform)).to eq(
        {
          id: platform.id.to_s,
          name: platform.name
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

      expect(result.graphql_dig(:platform_search, :nodes)).to eq(
        [{
          id: platform.id.to_s,
          name: platform.name
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

      expect(result.graphql_dig(:platforms, :nodes)).to contain_exactly(
        {
          id: platform.id.to_s,
          name: platform.name
        },
        {
          id: platform2.id.to_s,
          name: platform2.name
        }
      )
    end

    it "returns platforms with the most games first when sorting by MOST_GAMES" do
      platform
      create_list(:game_platform, 2, platform: platform2)
      create(:game_platform, platform: platform)
      platform3 = create(:platform)
      query_string = <<-GRAPHQL
        query {
          platforms(sortBy: MOST_GAMES) {
            nodes {
              id
            }
            totalCount
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:platforms, :nodes)).to eq(
        [platform2, platform, platform3].map { |record| { id: record.id.to_s } }
      )
      expect(result.graphql_dig(:platforms, :total_count)).to eq(3)
    end
  end
end
