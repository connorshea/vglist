# typed: false
require 'rails_helper'

RSpec.describe "Live Statistics API", type: :request do
  describe "Query for data on current live statistics" do
    context 'when signed in as an admin' do
      let(:user) { create(:confirmed_admin) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
      let(:game) { create(:game_with_everything) }

      it "returns basic data for live statistics" do
        query_string = <<-GRAPHQL
          query {
            liveStatistics {
              id
              timestamp
              users
              games
              platforms
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:live_statistics)).to eq(
          {
            id: nil,
            timestamp: nil,
            users: 1,
            games: 0,
            platforms: 0
          }
        )
      end

      it "returns all data for live statistics" do
        game
        query_string = <<-GRAPHQL
          query {
            liveStatistics {
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
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:live_statistics)).to eq(
          {
            id: nil,
            timestamp: nil,
            users: 1,
            games: 1,
            platforms: 1,
            series: 1,
            engines: 1,
            companies: 2,
            genres: 1,
            stores: 0,
            events: 1,
            gamePurchases: 0,
            relationships: 0,
            gamesWithCovers: 1,
            gamesWithReleaseDates: 1,
            bannedUsers: 0,
            mobygamesIds: 1,
            pcgamingwikiIds: 1,
            wikidataIds: 1,
            giantbombIds: 1,
            steamAppIds: 1,
            epicGamesStoreIds: 1,
            gogIds: 1,
            igdbIds: 1,
            companyVersions: 0,
            gameVersions: 0,
            genreVersions: 0,
            engineVersions: 0,
            platformVersions: 0,
            seriesVersions: 0
          }
        )
      end
    end

    context 'when signed in as a normal user' do
      let(:user) { create(:confirmed_user) }
      let(:application) { build(:application, owner: user) }
      let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

      it "returns a permissions error for statistics" do
        query_string = <<-GRAPHQL
          query {
            liveStatistics {
              id
              timestamp
              games
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(api_result_errors(result)).to include('Viewing site statistics is only available to admins.')
        expect(result.graphql_dig(:live_statistics)).to be_nil
      end
    end
  end
end
