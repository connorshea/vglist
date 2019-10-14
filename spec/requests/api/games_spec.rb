# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game2) { create(:game) }
    let(:game_with_cover) { create(:game_with_cover) }
    let(:game_with_release_date) { create(:game_with_release_date) }

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

    it "returns other data for game" do
      sign_in(user)
      game_with_release_date
      query_string = <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
            releaseDate
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: game_with_release_date.id }
      )

      expect(result.to_h["data"]["game"]).to eq(
        {
          "id" => game_with_release_date.id.to_s,
          "name" => game_with_release_date.name,
          "releaseDate" => game_with_release_date.release_date.strftime("%F")
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

    it "returns data for games when listing" do
      sign_in(user)
      game
      game2
      query_string = <<-GRAPHQL
        query {
          games {
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
      expect(result.to_h["data"]["games"]["nodes"]).to eq(
        [
          {
            "id" => game.id.to_s,
            "name" => game.name
          },
          {
            "id" => game2.id.to_s,
            "name" => game2.name
          }
        ]
      )
    end
  end
end
