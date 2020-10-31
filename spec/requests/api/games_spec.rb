# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game) { create(:game) }
    let(:game2) { create(:game) }
    let(:game_with_cover) { create(:game_with_cover) }
    let(:game_with_release_date) { create(:game_with_release_date) }
    let(:game_with_steam_app_ids) { create(:game_with_steam_app_id) }

    it "returns basic data for game" do
      game
      query_string = <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result["data"]["game"]).to eq(
        {
          "id" => game.id.to_s,
          "name" => game.name
        }
      )
    end

    it "returns data for game with steam app id" do
      game_with_steam_app_ids
      query_string = <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            id
            name
            steamAppIds
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: game_with_steam_app_ids.id }, token: access_token)

      expect(result["data"]["game"]).to eq(
        {
          "id" => game_with_steam_app_ids.id.to_s,
          "name" => game_with_steam_app_ids.name,
          "steamAppIds" => game_with_steam_app_ids.steam_app_ids.map(&:app_id)
        }
      )
    end

    it "returns cover for game" do
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

      result = api_request(query_string, variables: { id: game_with_cover.id }, token: access_token)

      expect(result["data"]["game"]).to eq(
        {
          "id" => game_with_cover.id.to_s,
          "name" => game_with_cover.name,
          "coverUrl" => Rails.application.routes.url_helpers.rails_blob_url(game_with_cover.cover_attachment, only_path: true)
        }
      )
    end

    it "returns other data for game" do
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

      result = api_request(query_string, variables: { id: game_with_release_date.id }, token: access_token)

      expect(result["data"]["game"]).to eq(
        {
          "id" => game_with_release_date.id.to_s,
          "name" => game_with_release_date.name,
          "releaseDate" => game_with_release_date.release_date.strftime("%F")
        }
      )
    end

    it "returns data for a game when searching" do
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

      result = api_request(query_string, variables: { query: game.name }, token: access_token)

      expect(result["data"]["gameSearch"]["nodes"]).to eq(
        [{
          "id" => game.id.to_s,
          "name" => game.name
        }]
      )
    end

    it "returns data for games when listing" do
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

      result = api_request(query_string, token: access_token)
      expect(result["data"]["games"]["nodes"]).to eq(
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
