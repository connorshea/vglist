# typed: false
require 'rails_helper'

RSpec.describe "CreatePlatform Mutation API", type: :request do
  describe "Mutation creates a new platform record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($name: String!, $wikidataId: Int!) {
          createPlatform(name: $name, wikidataId: $wikidataId) {
            platform {
              name
              wikidataId
            }
          }
        }
      GRAPHQL
    end

    [:moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "increases the number of platforms" do
          expect do
            api_request(query_string, variables: { name: 'Nintendo Switch', wikidata_id: 123 }, token: access_token)
          end.to change(Platform, :count).by(1)
        end

        it "returns basic data for platform after creation" do
          result = api_request(query_string, variables: { name: 'Nintendo Switch', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:create_platform, :platform)).to eq(
            {
              name: 'Nintendo Switch',
              wikidataId: 123
            }
          )
        end
      end
    end
  end
end
