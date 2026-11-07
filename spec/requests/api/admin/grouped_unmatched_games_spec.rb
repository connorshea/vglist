# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Grouped Unmatched Games API", type: :request do
  describe "Query for data on UnmatchedGame entries" do
    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:access_token) { JwtService.encode(user) }
      let(:unmatched_games) { create_list(:unmatched_game, 3, name: 'Half-Life', external_service_id: '123') }
      let(:unmatched_game1) { create(:unmatched_game, name: 'Half-Life 2', external_service_id: '124') }
      let(:query_string) do
        <<-GRAPHQL
          query {
            groupedUnmatchedGames {
              nodes {
                externalServiceId
                externalServiceName
                name
                count
              }
            }
          }
        GRAPHQL
      end

      it "returns basic data for unmatched games entries" do
        unmatched_games
        unmatched_game1

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:grouped_unmatched_games, :nodes).length).to eq(2)
        expect(result.graphql_dig(:grouped_unmatched_games, :nodes)).to include(
          {
            externalServiceId: unmatched_game1.external_service_id,
            externalServiceName: 'STEAM',
            name: unmatched_game1.name,
            count: 1
          },
          {
            externalServiceId: '123',
            externalServiceName: 'STEAM',
            name: 'Half-Life',
            count: 3
          }
        )
      end

      it "pages through games with the same count without repeating or skipping any" do
        create(:unmatched_game, name: 'C', external_service_id: '3')
        create(:unmatched_game, name: 'A', external_service_id: '1')
        create(:unmatched_game, name: 'B', external_service_id: '2')
        page_query = <<-GRAPHQL
          query($after: String) {
            groupedUnmatchedGames(first: 2, after: $after) {
              nodes { externalServiceId }
              pageInfo { hasNextPage endCursor }
            }
          }
        GRAPHQL

        first_page = api_request(page_query, token: access_token).graphql_dig(:grouped_unmatched_games)
        second_page = api_request(page_query, token: access_token, variables: { after: first_page.dig(:pageInfo, :endCursor) }).graphql_dig(:grouped_unmatched_games)

        expect((first_page[:nodes] + second_page[:nodes]).pluck(:externalServiceId)).to eq(['1', '2', '3'])
      end
    end
  end
end
