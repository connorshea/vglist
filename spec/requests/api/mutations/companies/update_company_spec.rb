require 'rails_helper'

RSpec.describe "UpdateCompany Mutation API", type: :request do
  describe "Mutation updates an existing company record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:company) { create(:company) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($companyId: ID!, $name: String, $wikidataId: ID) {
          updateCompany(companyId: $companyId, name: $name, wikidataId: $wikidataId) {
            company {
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

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not update the company" do
        expect do
          result = api_request(query_string, variables: { company_id: company.id, name: 'Electronic Arts', wikidata_id: 123 }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update this company.")
        end.not_to change(company.reload, :name).from('Valve Corporation')
      end
    end
  end
end
