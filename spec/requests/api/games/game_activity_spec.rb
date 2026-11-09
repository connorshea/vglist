# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Game activity API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }
  let(:game) { create(:game) }
  let(:other_game) { create(:game) }
  let(:private_user) { create(:private_user) }
  let(:banned_user) { create(:banned_user) }

  describe "activity" do
    let(:query_string) do
      <<-GRAPHQL
        query($id: ID!) {
          game(id: $id) {
            activity {
              nodes {
                eventCategory
                user { id }
                eventable {
                  __typename
                  ... on GamePurchase { id }
                  ... on FavoriteGame { id }
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it "returns library, completion and favorite events for the game, newest first" do
      purchase = create(:game_purchase, game: game, user: user)
      purchase.update!(completion_status: :completed)
      favorite = create(:favorite_game, game: game, user: user)
      create(:game_purchase, game: other_game, user: user)
      create(:favorite_game, game: other_game, user: user)

      result = api_request(query_string, variables: { id: game.id }, token: access_token)
      nodes = result.graphql_dig(:game, :activity, :nodes)

      expect(nodes.pluck(:eventCategory)).to contain_exactly('ADD_TO_LIBRARY', 'CHANGE_COMPLETION_STATUS', 'FAVORITE_GAME')
      expect(nodes.pluck(:eventable)).to contain_exactly(
        { __typename: 'GamePurchase', id: purchase.id.to_s },
        { __typename: 'GamePurchase', id: purchase.id.to_s },
        { __typename: 'FavoriteGame', id: favorite.id.to_s }
      )
    end

    it "orders events newest first" do
      first = create(:game_purchase, game: game)
      second = create(:game_purchase, game: game)
      Events::GamePurchaseEvent.find_by!(eventable_id: first.id).update!(created_at: 2.days.ago)
      Events::GamePurchaseEvent.find_by!(eventable_id: second.id).update!(created_at: 1.day.ago)

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:game, :activity, :nodes).map { |n| n.dig(:eventable, :id) }).to eq([second.id.to_s, first.id.to_s])
    end

    it "pages through the events" do
      purchases = Array.new(3) { create(:game_purchase, game: game) }
      purchases.each_with_index do |purchase, i|
        Events::GamePurchaseEvent.find_by!(eventable_id: purchase.id).update!(created_at: (3 - i).days.ago)
      end
      paged_query = <<-GRAPHQL
        query($id: ID!, $after: String) {
          game(id: $id) {
            activity(first: 2, after: $after) {
              nodes { eventable { ... on GamePurchase { id } } }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
      GRAPHQL

      first_page = api_request(paged_query, variables: { id: game.id }, token: access_token).graphql_dig(:game, :activity)
      second_page = api_request(
        paged_query, variables: { id: game.id, after: first_page.dig(:pageInfo, :endCursor) }, token: access_token
      ).graphql_dig(:game, :activity)

      summary = [first_page, second_page].map do |page|
        [page[:nodes].map { |n| n.dig(:eventable, :id) }, page.dig(:pageInfo, :hasNextPage)]
      end
      expected = [[[purchases[2].id.to_s, purchases[1].id.to_s], true], [[purchases[0].id.to_s], false]]
      expect(summary).to eq(expected)
    end

    it "hides events from private and banned users" do
      [user, private_user, banned_user].each do |u|
        create(:game_purchase, game: game, user: u)
        create(:favorite_game, game: game, user: u)
      end

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:game, :activity, :nodes).map { |n| n.dig(:user, :id) }.uniq).to eq([user.id.to_s])
    end

    describe "preloading" do
      # The SQL statements run while answering `query_string`.
      def queries_for(query_string)
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          api_request(query_string, variables: { id: game.id }, token: access_token)
        end
        queries
      end

      before(:each) do
        create(:game_purchase, game: game, user: user)
        create(:favorite_game, game: game, user: user)
      end

      it "doesn't load the eventables' games when they aren't selected" do
        # Only the game being looked up.
        expect(queries_for(query_string).grep(/FROM "games"/).size).to eq(1)
      end

      it "preloads the eventables' games when they are selected" do
        with_games = <<-GRAPHQL
          query($id: ID!) {
            game(id: $id) {
              activity {
                nodes {
                  eventable {
                    ... on GamePurchase { game { name } }
                    ... on FavoriteGame { game { name } }
                  }
                }
              }
            }
          }
        GRAPHQL

        # The game being looked up, then one preload per event table.
        expect(queries_for(with_games).grep(/FROM "games"/).size).to eq(3)
      end
    end
  end
end
