# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_with_cover) { create(:game_with_cover) }

    it "returns basic data for game" do
      sign_in(user)
      game
      query_string = <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game.id }
      )
      expect(result.to_h["data"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end

    it "returns cover for game" do
      sign_in(user)
      game_with_cover
      query_string = <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
            coverUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game_with_cover.id }
      )
      expect(result.to_h["data"]["game"]).to eq(
        {
          "id" => game_with_cover.id.to_s,
          "name" => game_with_cover.name,
          "coverUrl" => Rails.application.routes.url_helpers.rails_blob_url(game_with_cover.cover_attachment, only_path: true)
        }
      )
    end

    it "returns data for a game when searching" do
      sign_in(user)
      game
      query_string = <<-GRAPHQL
        query($query: String!) {
          gameSearch(query: $query) {
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
        variables: { query: game.name }
      )
      expect(result.to_h["data"]["gameSearch"]["nodes"]).to eq(
        [{
          "id" => game.id.to_s,
          "name" => game.name
        }]
      )
    end
  end
end
