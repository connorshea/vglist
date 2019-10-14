# typed: false
require 'rails_helper'

RSpec.describe "Companies API", type: :request do
  describe "Query for data on companies" do
    let(:user) { create(:confirmed_user) }
    let(:company) { create(:company) }
    let(:company2) { create(:company) }

    it "returns basic data for company" do
      sign_in(user)
      company
      query_string = <<-GRAPHQL
        query($id: ID!) {
          company(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: company.id }
      )
      expect(result.to_h["data"]["company"]).to eq(
        {
          "id" => company.id.to_s,
          "name" => company.name
        }
      )
    end

    it "returns data for a company when searching" do
      sign_in(user)
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

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { query: company.name }
      )
      expect(result.to_h["data"]["companySearch"]["nodes"]).to eq(
        [{
          "id" => company.id.to_s,
          "name" => company.name
        }]
      )
    end

    it "returns data for companies when listing" do
      sign_in(user)
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

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )
      expect(result.to_h["data"]["companies"]["nodes"]).to eq(
        [
          {
            "id" => company.id.to_s,
            "name" => company.name
          },
          {
            "id" => company2.id.to_s,
            "name" => company2.name
          }
        ]
      )
    end
  end
end
