# typed: false
require 'rails_helper'

RSpec.describe "Remove from Wikidata Blocklist Mutation API", type: :request do
  describe "Mutation removes the Wikidata blocklist entry" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          removeFromWikidataBlocklist(wikidataBlocklistEntryId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:wikidata_blocklist_entry) { create(:wikidata_blocklist) }

      it "decreases the number of Wikidata blocklist entries" do
        wikidata_blocklist_entry

        expect do
          api_request(query_string, variables: { id: wikidata_blocklist_entry.id }, token: access_token)
        end.to change(WikidataBlocklist, :count).by(-1)
      end

      it "returns deleted true" do
        result = api_request(query_string, variables: { id: wikidata_blocklist_entry.id }, token: access_token)

        expect(result.graphql_dig(:remove_from_wikidata_blocklist, :deleted)).to eq(true)
      end
    end
  end
end
