# typed: false
require 'rails_helper'

RSpec.describe "Genres API", type: :request do
  describe "Query for data on genres" do
    let(:user) { create(:confirmed_user) }
    let(:genre) { create(:genre) }

    it "returns basic data for genre" do
      sign_in(user)
      genre
      query_string = <<-GRAPHQL
        query($id: ID!) {
          genre(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: genre.id }
      )
      expect(result.to_h["data"]["genre"]).to eq(
        {
          "id" => genre.id.to_s,
          "name" => genre.name
        }
      )
    end

    it "returns data for a genre when searching" do
      sign_in(user)
      genre
      query_string = <<-GRAPHQL
        query($query: String!) {
          genreSearch(query: $query) {
            id
            name
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { query: genre.name }
      )
      expect(result.to_h["data"]["genreSearch"]).to eq(
        [{
          "id" => genre.id.to_s,
          "name" => genre.name
        }]
      )
    end
  end
end
