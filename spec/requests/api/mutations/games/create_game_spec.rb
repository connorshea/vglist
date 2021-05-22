# typed: false
require 'rails_helper'

RSpec.describe "CreateGame Mutation API", type: :request do
  describe "Mutation creates a game record" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with basic game' do
      let(:query_string) do
        <<-GRAPHQL
          mutation($name: String!) {
            createGame(name: $name) {
              game {
                id
                name
              }
            }
          }
        GRAPHQL
      end

      it "creates a game" do
        expect do
          api_request(query_string, variables: { name: 'Half-Life' }, token: access_token)
        end.to change(Game, :count).by(1)
      end

      it "returns basic data for game after creating it" do
        result = api_request(query_string, variables: { name: 'Half-Life' }, token: access_token)

        expect(result.graphql_dig(:create_game, :game, :name)).to eq('Half-Life')
      end
    end

    context 'with more complex game' do
      let(:query_string) do
        <<-GRAPHQL
          mutation(
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
            $wikidataId: Int,
            $igdbId: String
          ) {
            createGame(
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
      let(:series) { create(:series) }
      let(:developer) { create(:company) }
      let(:publisher) { create(:company) }
      let(:platform) { create(:platform) }
      let(:engine) { create(:engine) }
      let(:genre) { create(:genre) }
      let(:variables) do
        {
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

      it "creates a game" do
        expect do
          api_request(query_string, variables: variables, token: access_token)
        end.to change(Game, :count).by(1)
      end

      it "returns the data for game after creating it" do
        result = api_request(query_string, variables: variables, token: access_token)

        expect(result.graphql_dig(:create_game, :game)).to eq(
          {
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
  end
end
