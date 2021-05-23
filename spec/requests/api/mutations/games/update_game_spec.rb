# typed: false
require 'rails_helper'

RSpec.describe "UpdateGame Mutation API", type: :request do
  describe "Mutation updates an existing game record" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with basic game' do
      let(:game) { create(:game, name: 'Half-Life') }
      let(:query_string) do
        <<-GRAPHQL
          mutation($gameId: ID!, $name: String!) {
            updateGame(gameId: $gameId, name: $name) {
              game {
                id
                name
              }
            }
          }
        GRAPHQL
      end

      it "updates the game" do
        game
        expect do
          api_request(query_string, variables: { game_id: game.id, name: 'Portal' }, token: access_token)
        end.not_to change(Game, :count)
      end

      it "returns basic data for game after updating it" do
        result = api_request(query_string, variables: { game_id: game.id, name: 'Portal' }, token: access_token)

        expect(result.graphql_dig(:update_game, :game, :name)).to eq('Portal')
      end
    end

    context 'with more complex game' do
      let(:query_string) do
        <<-GRAPHQL
          mutation(
            $gameId: ID!,
            $name: String!,
            $releaseDate: ISO8601Date,
            $seriesId: ID,
            $developerIds: [ID!],
            $publisherIds: [ID!],
            $platformIds: [ID!],
            $engineIds: [ID!],
            $genreIds: [ID!],
            $steamAppIds: [Int!],
            $gogId: String,
            $epicGamesStoreId: String,
            $mobygamesId: String,
            $giantbombId: String,
            $pcgamingwikiId: String,
            $wikidataId: ID,
            $igdbId: String
          ) {
            updateGame(
              gameId: $gameId,
              name: $name,
              releaseDate: $releaseDate,
              seriesId: $seriesId,
              developerIds: $developerIds,
              publisherIds: $publisherIds,
              platformIds: $platformIds,
              engineIds: $engineIds,
              genreIds: $genreIds,
              steamAppIds: $steamAppIds,
              gogId: $gogId,
              epicGamesStoreId: $epicGamesStoreId,
              mobygamesId: $mobygamesId,
              giantbombId: $giantbombId
              pcgamingwikiId: $pcgamingwikiId,
              wikidataId: $wikidataId,
              igdbId: $igdbId
            ) {
              game {
                id
                name
                releaseDate
                series {
                  id
                }
                developers {
                  nodes {
                    id
                  }
                }
                publishers {
                  nodes {
                    id
                  }
                }
                platforms {
                  nodes {
                    id
                  }
                }
                engines {
                  nodes {
                    id
                  }
                }
                genres {
                  nodes {
                    id
                  }
                }
                steamAppIds
                gogId
                epicGamesStoreId
                giantbombId
                mobygamesId
                pcgamingwikiId
                wikidataId
                igdbId
              }
            }
          }
        GRAPHQL
      end
      let(:game) { create(:game, name: 'Portal') }
      let(:series) { create(:series) }
      let(:developer) { create(:company) }
      let(:publisher) { create(:company) }
      let(:platform) { create(:platform) }
      let(:engine) { create(:engine) }
      let(:genre) { create(:genre) }
      let(:variables) do
        {
          game_id: game.id,
          name: 'Portal 2',
          release_date: '2011-04-18',
          series_id: series.id,
          developer_ids: [developer.id],
          publisher_ids: [publisher.id],
          platform_ids: [platform.id],
          engine_ids: [engine.id],
          genre_ids: [genre.id],
          steam_app_ids: [123, 456],
          gog_id: 'portal_2',
          epic_games_store_id: 'foo',
          giantbomb_id: '3030-1539',
          mobygames_id: 'bar',
          pcgamingwiki_id: 'baz',
          wikidata_id: 123_456_789,
          igdb_id: 'portal-2'
        }
      end

      it "updates the game" do
        game
        expect do
          api_request(query_string, variables: variables, token: access_token)
        end.not_to change(Game, :count)
      end

      it "returns the data for game after updating it" do
        result = api_request(query_string, variables: variables, token: access_token)

        expect(result.graphql_dig(:update_game, :game)).to eq(
          {
            id: game.id.to_s,
            name: 'Portal 2',
            releaseDate: '2011-04-18',
            series: {
              id: series.id.to_s
            },
            developers: {
              nodes: [
                id: developer.id.to_s
              ]
            },
            publishers: {
              nodes: [
                id: publisher.id.to_s
              ]
            },
            platforms: {
              nodes: [
                id: platform.id.to_s
              ]
            },
            engines: {
              nodes: [
                id: engine.id.to_s
              ]
            },
            genres: {
              nodes: [
                id: genre.id.to_s
              ]
            },
            steamAppIds: [123, 456],
            gogId: 'portal_2',
            epicGamesStoreId: 'foo',
            giantbombId: '3030-1539',
            mobygamesId: 'bar',
            pcgamingwikiId: 'baz',
            wikidataId: 123_456_789,
            igdbId: 'portal-2'
          }
        )
      end
    end

    context 'with game that has Steam AppIDs' do
      let(:game) do
        create(:game, name: 'Half-Life') do |game|
          create(:steam_app_id, game: game, app_id: 123)
          create(:steam_app_id, game: game, app_id: 124)
        end
      end
      let(:query_string) do
        <<-GRAPHQL
          mutation($gameId: ID!, $name: String!, $steamAppIds: [Int!]) {
            updateGame(gameId: $gameId, name: $name, steamAppIds: $steamAppIds) {
              game {
                id
                name
                steamAppIds
              }
            }
          }
        GRAPHQL
      end

      it "updates the game" do
        game
        expect do
          api_request(query_string, variables: { game_id: game.id, name: 'Portal', steam_app_ids: [123, 125] }, token: access_token)
        end.not_to change(Game, :count)
      end

      it "returns data for game after updating it and updates the SteamAppId records correctly" do
        result = api_request(query_string, variables: { game_id: game.id, name: 'Portal', steam_app_ids: [123, 125] }, token: access_token)

        expect(result.graphql_dig(:update_game, :game)).to eq(
          {
            id: game.id.to_s,
            name: 'Portal',
            steamAppIds: [123, 125]
          }
        )
      end

      it "returns data for game after updating it and does not touch SteamAppIds" do
        result = api_request(query_string, variables: { game_id: game.id, name: 'Portal' }, token: access_token)

        expect(result.graphql_dig(:update_game, :game)).to eq(
          {
            id: game.id.to_s,
            name: 'Portal',
            steamAppIds: [123, 124]
          }
        )
      end
    end
  end
end
