# typed: false
require 'rails_helper'

RSpec.describe "Genres API", type: :request do
  describe "Query for data on genres" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:genre) { create(:genre) }
    let(:genre2) { create(:genre) }

    it "returns basic data for genre" do
      genre
      query_string = <<-GRAPHQL
        query($id: ID!) {
          genre(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: genre.id }, token: access_token)

      expect(result.graphql_dig(:genre)).to eq(
        {
          id: genre.id.to_s,
          name: genre.name
        }
      )
    end

    it "returns data for a genre when searching" do
      genre
      query_string = <<-GRAPHQL
        query($query: String!) {
          genreSearch(query: $query) {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: genre.name }, token: access_token)

      expect(result.graphql_dig(:genre_search, :nodes)).to eq(
        [{
          id: genre.id.to_s,
          name: genre.name
        }]
      )
    end

    it "returns data for genres when listing" do
      genre
      genre2
      query_string = <<-GRAPHQL
        query {
          genres {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:genres, :nodes)).to eq(
        [
          {
            id: genre.id.to_s,
            name: genre.name
          },
          {
            id: genre2.id.to_s,
            name: genre2.name
          }
        ]
      )
    end
  end
end
