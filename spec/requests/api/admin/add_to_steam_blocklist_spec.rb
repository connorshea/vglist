# typed: false
require 'rails_helper'

RSpec.describe "Add to Steam Blocklist Mutation API", type: :request do
  describe "Mutation creates the Steam blocklist entry" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation ($name: String!, $steamAppId: Int!) {
          addToSteamBlocklist(name: $name, steamAppId: $steamId) {
            steamBlocklistEntry {
              name
              steamAppId
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }

      it "increases the number of Steam blocklist entries" do
        expect do
          api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)
        end.to change(SteamBlocklist, :count).by(1)
      end

      it "returns data about newly created blocklist entry" do
        result = api_request(query_string, variables: { name: 'foobar', steam_app_id: 123 }, token: access_token)

        expect(result.graphql_dig(:add_to_steam_blocklist, :steam_blocklist_entry)).to eq(
          {
            name: 'foobar',
            steamAppId: 123
          }
        )
      end
    end
  end
end
