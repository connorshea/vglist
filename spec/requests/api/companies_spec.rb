# typed: false
require 'rails_helper'

RSpec.describe "Companies API", type: :request do
  describe "Query for data on companies" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:company) { create(:company) }
    let(:company2) { create(:company) }

    it "returns basic data for company" do
      company
      query_string = <<-GRAPHQL
        query($id: ID!) {
          company(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: company.id }, token: access_token)

      expect(result.graphql_dig(:company)).to eq(
        {
          id: company.id.to_s,
          name: company.name
        }
      )
    end

    it "returns data for a company when searching" do
      company
      query_string = <<-GRAPHQL
        query($query: String!) {
          companySearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: company.name }, token: access_token)

      expect(result.graphql_dig(:companySearch, :nodes)).to eq(
        [{
          id: company.id.to_s,
          name: company.name
        }]
      )
    end

    it "returns data for companies when listing" do
      company
      company2
      query_string = <<-GRAPHQL
        query {
          companies {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:companies, :nodes)).to eq(
        [
          {
            id: company.id.to_s,
            name: company.name
          },
          {
            id: company2.id.to_s,
            name: company2.name
          }
        ]
      )
    end
  end
end
