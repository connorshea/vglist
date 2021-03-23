# typed: false
require 'rails_helper'

RSpec.describe "CreateCompany Mutation API", type: :request do
  describe "Mutation creates a new company record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($name: String!, $wikidataId: ID!) {
          createCompany(name: $name, wikidataId: $wikidataId) {
            company {
              name
              wikidataId
            }
          }
        }
      GRAPHQL
    end

    [:user, :moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "increases the number of companies" do
          expect do
            api_request(query_string, variables: { name: 'Valve', wikidata_id: 123 }, token: access_token)
          end.to change(Company, :count).by(1)
        end

        it "returns basic data for company after creation" do
          result = api_request(query_string, variables: { name: 'Valve', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:create_company, :company)).to eq(
            {
              name: 'Valve',
              wikidataId: 123
            }
          )
        end
      end
    end
  end
end
