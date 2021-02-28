# typed: false
require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with basic games query' do
      let!(:game) { create(:game) }
      let!(:game2) { create(:game) }

      it "returns data for games when listing" do
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
    end

    context 'when sorting games' do
      let(:games) { create_list(:game, 3) }

      # Test each sort order and make sure it matches the corresponding sort
      # method. We test the sort scopes individually in method specs, so we
      # should be able to rely on those tests for testing the specific order.
      [:newest, :oldest, :recently_updated, :least_recently_updated, :most_favorites, :most_owners, :recently_released, :highest_avg_rating].each do |sort_order|
        it "returns data in expected order for #{sort_order}" do
          query_string = <<~GRAPHQL_WITH_INTERP
            query {
              games(sortBy: #{sort_order.upcase}) {
                nodes {
                  id
                  name
                }
              }
            }
          GRAPHQL_WITH_INTERP

          games
          result = api_request(query_string, token: access_token)
          # This is a bit of a hack to get the games in the same format as
          # they're returned by GraphQL (hashes with only the specific
          # requested keys, with IDs being strings).
          expected_games = Game.public_send(sort_order).select(:id, :name).map(&:as_json).map(&:symbolize_keys).map do |game|
            game[:id] = game[:id].to_s
            game
          end

          expect(result.graphql_dig(:games, :nodes)).to eq(expected_games)
        end
      end
    end

    context 'when filtering by year' do
      let!(:game2017) { create(:game, release_date: Faker::Date.in_date_period(year: 2017)) }
      let!(:game2018) { create(:game, release_date: Faker::Date.in_date_period(year: 2018)) }
      let!(:game2019) { create(:game, release_date: Faker::Date.in_date_period(year: 2019)) }

      it "returns expected data when given a specific year" do
        query_string = <<~GRAPHQL
          query {
            games(byYear: 2018) {
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
              id: game2018.id.to_s,
              name: game2018.name
            }
          ]
        )

        expect(result.graphql_dig(:games, :nodes)).not_to include(
          { id: game2017.id.to_s, name: game2017.name },
          { id: game2019.id.to_s, name: game2019.name }
        )
      end
    end

    context 'when filtering by an invalid year' do
      let(:game) { create(:game, release_date: Faker::Date.in_date_period(year: 2017)) }

      it "returns null and error when given a year before 1950" do
        query_string = <<~GRAPHQL
          query {
            games(byYear: 1940) {
              nodes {
                id
                name
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        expect(result.graphql_dig(:games)).to be_nil
        expect(api_result_errors(result)).to include('byYear must be greater than or equal to 1950')
      end
    end

    context 'when filtering by platform' do
      let(:platform1) { create(:platform) }
      let(:platform2) { create(:platform) }
      let!(:game) { create(:game, platforms: [platform1]) }
      let!(:game2) { create(:game, platforms: [platform2]) }
      let!(:game3) { create(:game, platforms: []) }

      it "returns expected data when given a specific platform" do
        query_string = <<~GRAPHQL
          query($platform: ID!) {
            games(onPlatform: $platform) {
              nodes {
                id
                name
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { platform: platform1.id }, token: access_token)
        expect(result.graphql_dig(:games, :nodes)).to eq(
          [
            {
              id: game.id.to_s,
              name: game.name
            }
          ]
        )

        expect(result.graphql_dig(:games, :nodes)).not_to include(
          { id: game2.id.to_s, name: game2.name },
          { id: game3.id.to_s, name: game3.name }
        )
      end
    end
  end
end
