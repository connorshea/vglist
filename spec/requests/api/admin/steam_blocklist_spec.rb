# typed: false
require 'rails_helper'

RSpec.describe "Steam Blocklist API", type: :request do
  describe "Query for data on steam blocklist entries" do
    context 'when signed in as an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:steam_blocklist_entries) { create_list(:steam_blocklist, 2) }

      it "returns basic data for steam blocklist entries" do
        steam_blocklist_entries
        query_string = <<-GRAPHQL
          query {
            steamBlocklist {
              nodes {
                id
                name
                steamAppId
                user {
                  id
                  username
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:steam_blocklist, :nodes).length).to eq(2)
        expect(result.graphql_dig(:steam_blocklist, :nodes).first).to eq(
          {
            id: steam_blocklist_entries.first.id.to_s,
            name: steam_blocklist_entries.first.name,
            steamAppId: steam_blocklist_entries.first.steam_app_id,
            user: {
              id: steam_blocklist_entries.first.user.id.to_s,
              username: steam_blocklist_entries.first.user.username
            }
          }
        )
      end
    end

    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:steam_blocklist_entry) { create(:steam_blocklist) }

      it "returns a permissions error" do
        steam_blocklist_entry
        query_string = <<-GRAPHQL
          query {
            steamBlocklist {
              nodes {
                id
                name
                steamAppId
                user {
                  id
                  username
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(api_result_errors(result)).to include('Viewing the Steam Blocklist is only available to admins.')
        expect(result.graphql_dig(:steam_blocklist)).to be_nil
      end
    end
  end
end
