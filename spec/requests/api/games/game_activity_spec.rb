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

    it "hides events from private and banned users" do
      [user, private_user, banned_user].each do |u|
        create(:game_purchase, game: game, user: u)
        create(:favorite_game, game: game, user: u)
      end

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:game, :activity, :nodes).map { |n| n.dig(:user, :id) }.uniq).to eq([user.id.to_s])
    end
  end
end
