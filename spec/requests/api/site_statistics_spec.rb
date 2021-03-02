# typed: false
require 'rails_helper'

RSpec.describe "Site Statistics API", type: :request do
  describe "Query for data on site statistics" do
    context 'when signed in as an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:statistic) { create(:statistic) }

      it "returns basic data for statistic" do
        statistic
        query_string = <<-GRAPHQL
          query {
            siteStatistics {
              nodes {
                id
                timestamp
                games
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:site_statistics, :nodes).first).to eq(
          {
            id: statistic.id.to_s,
            timestamp: statistic.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            games: statistic.games
          }
        )
      end

      it "returns all data for statistic" do
        statistic
        query_string = <<-GRAPHQL
          query {
            siteStatistics {
              nodes {
                id
                timestamp
                users
                games
                platforms
                series
                engines
                companies
                genres
                stores
                events
                gamePurchases
                relationships
                gamesWithCovers
                gamesWithReleaseDates
                bannedUsers
                mobygamesIds
                pcgamingwikiIds
                wikidataIds
                giantbombIds
                steamAppIds
                epicGamesStoreIds
                gogIds
                igdbIds
                companyVersions
                gameVersions
                genreVersions
                engineVersions
                platformVersions
                seriesVersions
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:site_statistics, :nodes).first).to eq(
          {
            id: statistic.id.to_s,
            timestamp: statistic.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            users: statistic.users,
            games: statistic.games,
            platforms: statistic.platforms,
            series: statistic.series,
            engines: statistic.engines,
            companies: statistic.companies,
            genres: statistic.genres,
            stores: statistic.stores,
            events: statistic.events,
            gamePurchases: statistic.game_purchases,
            relationships: statistic.relationships,
            gamesWithCovers: statistic.games_with_covers,
            gamesWithReleaseDates: statistic.games_with_release_dates,
            bannedUsers: statistic.banned_users,
            mobygamesIds: statistic.mobygames_ids,
            pcgamingwikiIds: statistic.pcgamingwiki_ids,
            wikidataIds: statistic.wikidata_ids,
            giantbombIds: statistic.giantbomb_ids,
            steamAppIds: statistic.steam_app_ids,
            epicGamesStoreIds: statistic.epic_games_store_ids,
            gogIds: statistic.gog_ids,
            igdbIds: statistic.igdb_ids,
            companyVersions: statistic.company_versions,
            gameVersions: statistic.game_versions,
            genreVersions: statistic.genre_versions,
            engineVersions: statistic.engine_versions,
            platformVersions: statistic.platform_versions,
            seriesVersions: statistic.series_versions
          }
        )
      end
    end

    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:statistic) { create(:statistic) }

      it "returns a permissions error for statistic" do
        statistic
        query_string = <<-GRAPHQL
          query {
            siteStatistics {
              nodes {
                id
                timestamp
                games
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(api_result_errors(result)).to include('Viewing site statistics is only available to admins.')
        expect(result.graphql_dig(:site_statistics)).to be_nil
      end
    end
  end
end
