# typed: false
require 'rails_helper'

RSpec.describe "Add to Wikidata Blocklist Mutation API", type: :request do
  describe "Mutation creates the Wikidata blocklist entry" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation ($name: String!, $wikidataId: Int!) {
          addToWikidataBlocklist(name: $name, wikidataId: $wikidataId) {
            wikidataBlocklistEntry {
              name
              wikidataId
            }
          }
        }
      GRAPHQL
    end

    context 'when the current user is an admin' do
      let(:user) { create(:confirmed_admin) }

      it "increases the number of Wikidata blocklist entries" do
        expect do
          api_request(query_string, variables: { name: 'foobar', wikidata_id: 123 }, token: access_token)
        end.to change(WikidataBlocklist, :count).by(1)
      end

      it "returns data about newly created blocklist entry" do
        result = api_request(query_string, variables: { name: 'foobar', wikidata_id: 123 }, token: access_token)

        expect(result.graphql_dig(:add_to_wikidata_blocklist, :wikidata_blocklist_entry)).to eq(
          {
            name: 'foobar',
            wikidataId: 123
          }
        )
      end
    end
  end
end
