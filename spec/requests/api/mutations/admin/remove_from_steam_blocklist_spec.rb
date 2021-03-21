# typed: false
require 'rails_helper'

RSpec.describe "Remove from Steam Blocklist Mutation API", type: :request do
  describe "Mutation removes the Steam blocklist entry" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeFromSteamBlocklist(steamBlocklistEntryId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:steam_blocklist_entry) { create(:steam_blocklist) }

      it "decreases the number of Steam blocklist entries" do
        steam_blocklist_entry

        expect do
          api_request(query_string, variables: { id: steam_blocklist_entry.id }, token: access_token)
        end.to change(SteamBlocklist, :count).by(-1)
      end

      it "returns deleted true" do
        result = api_request(query_string, variables: { id: steam_blocklist_entry.id }, token: access_token)

        expect(result.graphql_dig(:remove_from_steam_blocklist, :deleted)).to eq(true)
      end
    end
  end
end
