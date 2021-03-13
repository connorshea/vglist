# typed: false
require 'rails_helper'

RSpec.describe "Game query API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game) { create(:game) }
    let(:game_with_cover) { create(:game_with_cover) }
    let(:game_with_release_date) { create(:game_with_release_date) }
    let(:game_with_steam_app_ids) { create(:game_with_steam_app_id) }
    let(:game_with_wikidata_id) { create(:game, :wikidata_id) }
    let(:game_with_giantbomb_id) { create(:game, :giantbomb_id) }
    let(:game_with_igdb_id) { create(:game, :igdb_id) }
    let(:game_with_mobygames_id) { create(:game, :mobygames_id) }
    let(:game_with_pcgamingwiki_id) { create(:game, :pcgamingwiki_id) }
    let(:game_with_steam_app_id) do
      create(:game) do |game|
        create(:steam_app_id, game: game)
      end
    end
    let(:game_with_epic_games_store_id) { create(:game, :epic_games_store_id) }
    let(:game_with_gog_id) { create(:game, :gog_id) }

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

    it "returns basic data for game when searching by wikidata_id" do
      query_string = <<-GRAPHQL
        query($wikidataId: Int!) {
          game(wikidataId: $wikidataId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { wikidata_id: game_with_wikidata_id.wikidata_id.to_i }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_wikidata_id.id.to_s,
          name: game_with_wikidata_id.name
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

    it "returns basic data for game when searching by igdb_id" do
      query_string = <<-GRAPHQL
        query($igdbId: String!) {
          game(igdbId: $igdbId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { igdb_id: game_with_igdb_id.igdb_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_igdb_id.id.to_s,
          name: game_with_igdb_id.name
        }
      )
    end

    it "returns basic data for game when searching by mobygames_id" do
      query_string = <<-GRAPHQL
        query($mobygamesId: String!) {
          game(mobygamesId: $mobygamesId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { mobygames_id: game_with_mobygames_id.mobygames_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_mobygames_id.id.to_s,
          name: game_with_mobygames_id.name
        }
      )
    end

    it "returns basic data for game when searching by pcgamingwiki_id" do
      query_string = <<-GRAPHQL
        query($pcgamingwikiId: String!) {
          game(pcgamingwikiId: $pcgamingwikiId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { pcgamingwiki_id: game_with_pcgamingwiki_id.pcgamingwiki_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_pcgamingwiki_id.id.to_s,
          name: game_with_pcgamingwiki_id.name
        }
      )
    end

    it "returns basic data for game when searching by steam_app_id" do
      query_string = <<-GRAPHQL
        query($steamAppId: Int!) {
          game(steamAppId: $steamAppId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { steam_app_id: game_with_steam_app_id.steam_app_ids.first.app_id.to_i }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_steam_app_id.id.to_s,
          name: game_with_steam_app_id.name
        }
      )
    end

    it "returns basic data for game when searching by epic_games_store_id" do
      query_string = <<-GRAPHQL
        query($epicGamesStoreId: String!) {
          game(epicGamesStoreId: $epicGamesStoreId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { epic_games_store_id: game_with_epic_games_store_id.epic_games_store_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_epic_games_store_id.id.to_s,
          name: game_with_epic_games_store_id.name
        }
      )
    end

    it "returns basic data for game when searching by gog_id" do
      query_string = <<-GRAPHQL
        query($gogId: String!) {
          game(gogId: $gogId) {
            id
            name
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { gog_id: game_with_gog_id.gog_id }, token: access_token)

      expect(result.graphql_dig(:game)).to eq(
        {
          id: game_with_gog_id.id.to_s,
          name: game_with_gog_id.name
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

    context 'with the current user having favorited the game' do
      let(:favorite_game) { create(:favorite_game, game: game, user: user) }
      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!) {
            game(id: $id) {
              isFavorited
            }
          }
        GRAPHQL
      end

      it "returns that the user has favorited the game" do
        favorite_game

        result = api_request(query_string, variables: { id: game.id }, token: access_token)
        expect(result.graphql_dig(:game)).to include(
          {
            isFavorited: true
          }
        )
      end

      it "returns that the user has not favorited the game" do
        result = api_request(query_string, variables: { id: game.id }, token: access_token)
        expect(result.graphql_dig(:game)).to include(
          {
            isFavorited: false
          }
        )
      end
    end

    context 'with the current user having added the game to their library' do
      let(:game_purchase) { create(:game_purchase, game: game, user: user) }
      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!) {
            game(id: $id) {
              isInLibrary
              gamePurchaseId
            }
          }
        GRAPHQL
      end

      it "returns that the user has added the game to their library" do
        game_purchase

        result = api_request(query_string, variables: { id: game.id }, token: access_token)
        expect(result.graphql_dig(:game)).to include(
          {
            isInLibrary: true,
            gamePurchaseId: game_purchase.id.to_s
          }
        )
      end

      it "returns that the user has not added the game to their library" do
        result = api_request(query_string, variables: { id: game.id }, token: access_token)
        expect(result.graphql_dig(:game)).to include(
          {
            isInLibrary: false,
            gamePurchaseId: nil
          }
        )
      end
    end
  end
end
