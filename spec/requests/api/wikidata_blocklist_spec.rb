# typed: false
require 'rails_helper'

RSpec.describe "Wikidata Blocklist API", type: :request do
  describe "Query for data on Wikidata blocklist entries" do
    context 'when signed in as an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:wikidata_blocklist_entries) { create_list(:wikidata_blocklist, 2) }

      it "returns basic data for wikidata blocklist entries" do
        wikidata_blocklist_entries
        query_string = <<-GRAPHQL
          query {
            wikidataBlocklist {
              nodes {
                id
                name
                wikidataId
                user {
                  id
                  username
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:wikidata_blocklist, :nodes).length).to eq(2)
        expect(result.graphql_dig(:wikidata_blocklist, :nodes).first).to eq(
          {
            id: wikidata_blocklist_entries.first.id.to_s,
            name: wikidata_blocklist_entries.first.name,
            wikidataId: wikidata_blocklist_entries.first.wikidata_id,
            user: {
              id: wikidata_blocklist_entries.first.user.id.to_s,
              username: wikidata_blocklist_entries.first.user.username
            }
          }
        )
      end
    end

    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:wikidata_blocklist_entry) { create(:wikidata_blocklist) }

      it "returns a permissions error" do
        wikidata_blocklist_entry
        query_string = <<-GRAPHQL
          query {
            wikidataBlocklist {
              nodes {
                id
                name
                wikidataId
                user {
                  id
                  username
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(api_result_errors(result)).to include('Viewing the Wikidata Blocklist is only available to admins.')
        expect(result.graphql_dig(:wikidata_blocklist)).to be_nil
      end
    end
  end
end
