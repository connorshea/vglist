# typed: false
require 'rails_helper'

RSpec.describe "Grouped Unmatched Games API", type: :request do
  describe "Query for data on UnmatchedGame entries" do
    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let!(:unmatched_games) { create_list(:unmatched_game, 3, name: 'Half-Life', external_service_id: '123') }
      let!(:unmatched_game1) { create(:unmatched_game, name: 'Half-Life 2', external_service_id: '124') }

      it "returns basic data for unmatched games entries" do
        query_string = <<-GRAPHQL
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
    end
  end
end
