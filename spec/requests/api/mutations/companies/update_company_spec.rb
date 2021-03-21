# typed: false
require 'rails_helper'

RSpec.describe "UpdateCompany Mutation API", type: :request do
  describe "Mutation updates an existing company record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:company) { create(:company) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($companyId: ID!, $name: String, $wikidataId: Int) {
          updateCompany(companyId: $companyId, name: $name, wikidataId: $wikidataId) {
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

        it "does not change the number of companies" do
          expect do
            api_request(query_string, variables: { company_id: company.id, name: 'Nintendo', wikidata_id: 123 }, token: access_token)
          end.not_to change(Company, :count)
        end

        it "returns basic data for company after creation" do
          result = api_request(query_string, variables: { company_id: company.id, name: 'Nintendo', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:update_company, :company)).to eq(
            {
              name: 'Nintendo',
              wikidataId: 123
            }
          )

          expect(company.reload.name).to eq('Nintendo')
          expect(company.reload.wikidata_id).to eq(123)
        end
      end
    end
  end
end
