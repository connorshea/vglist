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
    let(:game_with_giantbomb_id) { create(:game, :giantbomb_id) }

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

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game.id.to_s,
          name: game.name
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

      expect(result.graphql_dig(:game)).to include(
        id: game_with_steam_app_ids.id.to_s,
        name: game_with_steam_app_ids.name,
        steamAppIds: game_with_steam_app_ids.steam_app_ids.map(&:app_id)
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

      cover_variant = game_with_cover.sized_cover(:small)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_cover.id.to_s,
          name: game_with_cover.name,
          coverUrl: Rails.application.routes.url_helpers.rails_representation_url(cover_variant)
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

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_release_date.id.to_s,
          name: game_with_release_date.name,
          releaseDate: game_with_release_date.release_date.strftime("%F")
        }
      )
    end

    it "returns basic data for game when searching by giantbomb_id" do
      query_string = <<-GRAPHQL
        query($giantbombId: String!) {
          game(giantbombId: $giantbombId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { giantbomb_id: game_with_giantbomb_id.giantbomb_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_giantbomb_id.id.to_s,
          name: game_with_giantbomb_id.name
        }
      )
    end

    it "returns an error if the query uses both an id and giantbomb_id" do
      query_string = <<-GRAPHQL
        query($id: ID!, $giantbombId: String!) {
          game(id: $id, giantbombId: $giantbombId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: game_with_giantbomb_id.id, giantbomb_id: game_with_giantbomb_id.giantbomb_id }, token: access_token)

      expect(result.graphql_dig(:game)).to be_nil
      expect(result.to_h["errors"].first['message']).to eq('Cannot provide more than one argument to game at a time.')
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

      expect(result.graphql_dig(:game_search, :nodes)).to include_hash_matching(
        id: game.id.to_s,
        name: game.name
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
      expect(result.graphql_dig(:games, :nodes)).to eq(
        [
          {
            id: game.id.to_s,
            name: game.name
          },
          {
            id: game2.id.to_s,
            name: game2.name
          }
        ]
      )
    end

    context 'with favoriters' do
      let!(:favorite_game) { create(:favorite_game, game: game) }

      it "returns user data for the game when they've favorited the game" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            game(id: $id) {
              favoriters {
                nodes {
                  id
                  username
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: game.id }, token: access_token)
        expect(result.graphql_dig(:game, :favoriters, :nodes)).to include(
          {
            id: favorite_game.user.id.to_s,
            username: favorite_game.user.username
          }
        )
      end
    end
  end
end
