# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Remove from Wikidata Blocklist Mutation API", type: :request do
  describe "Mutation removes the Wikidata blocklist entry" do
    let(:access_token) { JwtService.encode(user) }
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

    [:moderator, :user].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }
        let!(:wikidata_blocklist_entry) { create(:wikidata_blocklist) }

        it "does not remove the Wikidata blocklist entry" do
          expect do
            result = api_request(query_string, variables: { id: wikidata_blocklist_entry.id }, token: access_token)
            expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove a Wikidata blocklist entry.")
          end.not_to change(WikidataBlocklist, :count)
        end
      end
    end

    context 'when there is no current user' do
      let!(:wikidata_blocklist_entry) { create(:wikidata_blocklist) }

      it "does not remove the Wikidata blocklist entry" do
        expect do
          result = api_request(query_string, variables: { id: wikidata_blocklist_entry.id }, token: nil)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to remove a Wikidata blocklist entry.")
        end.not_to change(WikidataBlocklist, :count)
      end
    end
  end
end
