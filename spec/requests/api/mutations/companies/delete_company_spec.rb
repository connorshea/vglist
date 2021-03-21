# typed: false
require 'rails_helper'

RSpec.describe "DeleteCompany Mutation API", type: :request do
  describe "Mutation deletes an existing company record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:company) { create(:company) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($companyId: ID!) {
          deleteCompany(companyId: $companyId) {
            deleted
          }
        }
      GRAPHQL
    end

    context "when the current user is an admin" do
      let(:user) { create(:confirmed_admin) }

      it "decreases the number of companies" do
        expect do
          api_request(query_string, variables: { company_id: company.id }, token: access_token)
        end.to change(Company, :count).by(-1)
      end

      it "returns true after deletion" do
        result = api_request(query_string, variables: { company_id: company.id }, token: access_token)

        expect(result.graphql_dig(:delete_company, :deleted)).to eq(true)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not change the number of companies" do
        expect do
          result = api_request(query_string, variables: { company_id: company.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this company.")
        end.not_to change(Company, :count)
      end
    end
  end
end
