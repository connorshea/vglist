# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Games API", type: :request do
  describe "Query for data on games" do
    let(:user) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }

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
        expect(result.graphql_dig(:games, :nodes)).to contain_exactly(
          {
            id: game.id.to_s,
            name: game.name
          },
          {
            id: game2.id.to_s,
            name: game2.name
          }
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

    context 'when counting games under a sort that groups them' do
      let!(:rated) { create(:game) }
      let!(:other) { create(:game) }

      before(:each) do
        create_list(:game_purchase, 5, game: rated, rating: 80)
        create(:game_purchase, game: other, rating: 40)
      end

      def total_count(sort_by)
        query_string = <<~GRAPHQL
          query {
            games(sortBy: #{sort_by}, first: 1) {
              totalCount
            }
          }
        GRAPHQL

        api_request(query_string, token: access_token).graphql_dig(:games, :total_count)
      end

      it "counts the games rather than returning one entry per group", :aggregate_failures do
        expect(total_count('MOST_OWNERS')).to eq(2)
        expect(total_count('MOST_FAVORITES')).to eq(2)
        # Only games with five or more ratings make the cut.
        expect(total_count('HIGHEST_AVG_RATING')).to eq(1)
      end

      it "counts in the database instead of loading every group" do
        sql = queries_run { total_count('MOST_FAVORITES') }.find { |q| q.include?('COUNT') }
        expect(sql).to match(/SELECT COUNT\(\*\) FROM \(SELECT/)
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

    context 'when filtering by a range of release years' do
      let!(:game2016) { create(:game, release_date: Date.new(2016, 12, 31)) }
      let!(:game2017) { create(:game, release_date: Date.new(2017, 1, 1)) }
      let!(:game2019) { create(:game, release_date: Date.new(2019, 12, 31)) }
      let!(:game2020) { create(:game, release_date: Date.new(2020, 1, 1)) }

      before(:each) do
        create(:game, release_date: nil)
      end

      def ids_for(arguments)
        query_string = <<~GRAPHQL
          query {
            games(#{arguments}) {
              nodes {
                id
              }
            }
          }
        GRAPHQL

        api_request(query_string, token: access_token).graphql_dig(:games, :nodes).pluck(:id)
      end

      it "includes both ends of the range" do
        expect(ids_for('fromYear: 2017, toYear: 2019')).to contain_exactly(game2017.id.to_s, game2019.id.to_s)
      end

      it "allows an open-ended range" do
        expect(ids_for('fromYear: 2019')).to contain_exactly(game2019.id.to_s, game2020.id.to_s)
        expect(ids_for('toYear: 2016')).to contain_exactly(game2016.id.to_s)
      end

      it "returns an error when given a year before 1950" do
        query_string = <<~GRAPHQL
          query {
            games(fromYear: 1940) {
              nodes {
                id
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        expect(result.graphql_dig(:games)).to be_nil
        expect(api_result_errors(result)).to include('fromYear must be greater than or equal to 1950')
      end
    end

    context 'when excluding games in the library' do
      let!(:owned_game) { create(:game) }
      let!(:other_game) { create(:game) }
      let(:query_string) do
        <<~GRAPHQL
          query {
            games(excludeLibrary: true) {
              nodes {
                id
              }
            }
          }
        GRAPHQL
      end

      before(:each) do
        create(:game_purchase, user: user, game: owned_game)
        create(:game_purchase, game: other_game)
      end

      it "leaves out the current user's games" do
        result = api_request(query_string, token: access_token)
        expect(result.graphql_dig(:games, :nodes)).to eq([{ id: other_game.id.to_s }])
      end

      it "returns every game when not authenticated" do
        post graphql_path, params: { query: query_string }
        ids = JSON.parse(response.body).dig('data', 'games', 'nodes').pluck('id')
        expect(ids).to contain_exactly(owned_game.id.to_s, other_game.id.to_s)
      end
    end

    context 'when requesting association fields on a games list' do
      let!(:game) { create(:game_with_everything) }

      it "returns association data for games", :aggregate_failures do
        query_string = <<~GRAPHQL
          query {
            games {
              nodes {
                id
                name
                series { id name }
                platforms { nodes { id name } }
                genres { nodes { id name } }
                developers { nodes { id name } }
                publishers { nodes { id name } }
                engines { nodes { id name } }
                steamAppIds
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        game_node = result.graphql_dig(:games, :nodes).find { |n| n[:id] == game.id.to_s }

        expect(game_node[:series][:name]).to eq(game.series.name)
        expect(game_node[:platforms][:nodes].first[:name]).to eq(game.platforms.first.name)
        expect(game_node[:genres][:nodes].first[:name]).to eq(game.genres.first.name)
        expect(game_node[:developers][:nodes].first[:name]).to eq(game.developers.first.name)
        expect(game_node[:publishers][:nodes].first[:name]).to eq(game.publishers.first.name)
        expect(game_node[:engines][:nodes].first[:name]).to eq(game.engines.first.name)
        expect(game_node[:steamAppIds]).to eq(game.steam_app_ids.map(&:app_id))
      end
    end

    context 'when requesting owner counts on a games list' do
      let!(:popular) { create(:game) }
      let!(:unowned) { create(:game) }
      let(:query_string) do
        <<~GRAPHQL
          query {
            games {
              nodes {
                id
                ownerCount
              }
            }
          }
        GRAPHQL
      end

      before(:each) do
        create_list(:game_purchase, 2, game: popular)
        create(:game_purchase, game: popular, user: create(:private_user))
        create(:game_purchase, game: popular, user: create(:banned_user))
      end

      it "counts each game's public, unbanned owners" do
        result = api_request(query_string, token: access_token)
        counts = result.graphql_dig(:games, :nodes).to_h { |n| [n[:id], n[:ownerCount]] }

        expect(counts).to eq(popular.id.to_s => 2, unowned.id.to_s => 0)
      end

      it "counts the owners of every game in one query" do
        # The first request warms up caches that would inflate its count.
        api_request(query_string, token: access_token)
        baseline = query_count { api_request(query_string, token: access_token) }
        create_list(:game, 3).each { |game| create(:game_purchase, game: game) }

        expect(query_count { api_request(query_string, token: access_token) }).to eq(baseline)
      end
    end

    context 'when requesting per-user fields on a games list' do
      let!(:game) { create(:game) }
      let!(:game2) { create(:game) }
      let!(:game_purchase) { create(:game_purchase, user: user, game: game) }

      before(:each) { create(:favorite_game, user: user, game: game) }

      it "returns isFavorited and isInLibrary fields", :aggregate_failures do
        query_string = <<~GRAPHQL
          query {
            games {
              nodes {
                id
                isFavorited
                isInLibrary
                gamePurchaseId
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        nodes = result.graphql_dig(:games, :nodes)
        owned_node = nodes.find { |n| n[:id] == game.id.to_s }
        unowned_node = nodes.find { |n| n[:id] == game2.id.to_s }

        expect(owned_node[:isFavorited]).to be true
        expect(owned_node[:isInLibrary]).to be true
        expect(owned_node[:gamePurchaseId]).to eq(game_purchase.id.to_s)
        expect(unowned_node[:isFavorited]).to be false
        expect(unowned_node[:isInLibrary]).to be false
        expect(unowned_node[:gamePurchaseId]).to be_nil
      end
    end

    context 'when requesting per-user fields across many games' do
      let!(:games) { create_list(:game, 5) }
      let!(:game_purchase1) { create(:game_purchase, user: user, game: games[0]) }
      let!(:game_purchase2) { create(:game_purchase, user: user, game: games[2]) }

      before(:each) do
        create(:favorite_game, user: user, game: games[0])
        create(:favorite_game, user: user, game: games[4])
      end

      it "returns correct per-user fields for each game", :aggregate_failures do
        query_string = <<~GRAPHQL
          query {
            games {
              nodes {
                id
                isFavorited
                isInLibrary
                gamePurchaseId
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        nodes = result.graphql_dig(:games, :nodes)

        # Game 0: owned + favorited
        node0 = nodes.find { |n| n[:id] == games[0].id.to_s }
        expect(node0[:isFavorited]).to be true
        expect(node0[:isInLibrary]).to be true
        expect(node0[:gamePurchaseId]).to eq(game_purchase1.id.to_s)

        # Game 1: neither
        node1 = nodes.find { |n| n[:id] == games[1].id.to_s }
        expect(node1[:isFavorited]).to be false
        expect(node1[:isInLibrary]).to be false
        expect(node1[:gamePurchaseId]).to be_nil

        # Game 2: owned but not favorited
        node2 = nodes.find { |n| n[:id] == games[2].id.to_s }
        expect(node2[:isFavorited]).to be false
        expect(node2[:isInLibrary]).to be true
        expect(node2[:gamePurchaseId]).to eq(game_purchase2.id.to_s)

        # Game 4: favorited but not owned
        node4 = nodes.find { |n| n[:id] == games[4].id.to_s }
        expect(node4[:isFavorited]).to be true
        expect(node4[:isInLibrary]).to be false
        expect(node4[:gamePurchaseId]).to be_nil
      end

      it "returns the current user's completion status for each game", :aggregate_failures do
        game_purchase1.update!(completion_status: :in_progress)
        query_string = <<~GRAPHQL
          query {
            games {
              nodes {
                id
                libraryCompletionStatus
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        statuses = result.graphql_dig(:games, :nodes).to_h { |n| [n[:id], n[:libraryCompletionStatus]] }

        expect(statuses[games[0].id.to_s]).to eq('IN_PROGRESS')
        # In the library, but without a status.
        expect(statuses[games[2].id.to_s]).to be_nil
        # Not in the library.
        expect(statuses[games[1].id.to_s]).to be_nil
      end

      it "returns nil for per-user fields when not authenticated", :aggregate_failures do
        query_string = <<~GRAPHQL
          query {
            games {
              nodes {
                id
                isFavorited
                isInLibrary
                gamePurchaseId
              }
            }
          }
        GRAPHQL

        post graphql_path, params: { query: query_string }
        json = JSON.parse(response.body)
        nodes = json.dig('data', 'games', 'nodes')

        nodes.each do |node|
          expect(node['isFavorited']).to be_nil
          expect(node['isInLibrary']).to be_nil
          expect(node['gamePurchaseId']).to be_nil
        end
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

    context 'when preloading associations for the games list' do
      let!(:game) { create(:game_with_everything) }
      let!(:game2) { create(:game_with_everything) }

      # Authenticating lazily would otherwise create the user, its avatar and
      # its JWT inside the measured block.
      before(:each) { access_token }

      it "doesn't preload associations the query didn't select" do
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

        tables = tables_queried { api_request(query_string, token: access_token) }

        expect(tables).to include('games')
        expect(tables).not_to include(
          'series', 'game_developers', 'game_publishers', 'game_engines',
          'game_genres', 'game_platforms', 'steam_app_ids', 'active_storage_attachments'
        )
      end

      it "preloads only the associations the query did select" do
        query_string = <<-GRAPHQL
          query {
            games {
              nodes {
                id
                developers { nodes { name } }
              }
            }
          }
        GRAPHQL

        tables = tables_queried { api_request(query_string, token: access_token) }

        expect(tables).to include('games', 'game_developers', 'companies')
        expect(tables).not_to include('game_platforms', 'game_genres', 'steam_app_ids')
      end

      it "preloads associations selected through edges and fragments" do
        query_string = <<-GRAPHQL
          query {
            games {
              edges {
                node {
                  id
                  ...GameFields
                }
              }
            }
          }

          fragment GameFields on Game {
            platforms { nodes { name } }
          }
        GRAPHQL

        tables = tables_queried { api_request(query_string, token: access_token) }

        expect(tables).to include('games', 'game_platforms', 'platforms')
        expect(tables).not_to include('game_developers', 'game_genres')
      end

      it "returns the same data regardless of which associations are preloaded" do
        query_string = <<-GRAPHQL
          query {
            games {
              nodes {
                id
                name
                steamAppIds
                series { name }
                developers { nodes { name } }
                platforms { nodes { name } }
                genres { nodes { name } }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)
        expect(result.graphql_dig(:games, :nodes)).to contain_exactly(
          {
            id: game.id.to_s,
            name: game.name,
            steamAppIds: game.steam_app_ids.map(&:app_id),
            series: { name: game.series.name },
            developers: { nodes: game.developers.map { |d| { name: d.name } } },
            platforms: { nodes: game.platforms.map { |p| { name: p.name } } },
            genres: { nodes: game.genres.map { |g| { name: g.name } } }
          },
          {
            id: game2.id.to_s,
            name: game2.name,
            steamAppIds: game2.steam_app_ids.map(&:app_id),
            series: { name: game2.series.name },
            developers: { nodes: game2.developers.map { |d| { name: d.name } } },
            platforms: { nodes: game2.platforms.map { |p| { name: p.name } } },
            genres: { nodes: game2.genres.map { |g| { name: g.name } } }
          }
        )
      end
    end
  end
end
