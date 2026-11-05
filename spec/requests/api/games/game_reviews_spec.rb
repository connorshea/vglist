# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Game reviews API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }
  let(:game) { create(:game) }
  let(:other_game) { create(:game) }
  let(:private_user) { create(:private_user) }
  let(:banned_user) { create(:banned_user) }

  describe "reviews" do
    let(:query_string) do
      <<-GRAPHQL
        query($id: ID!, $sortBy: GameReviewSort) {
          game(id: $id) {
            reviews(sortBy: $sortBy) {
              totalCount
              nodes { id comments rating user { id } }
            }
          }
        }
      GRAPHQL
    end

    it "returns library entries with comments, newest first" do
      older = create(:game_purchase, game: game, comments: 'Older review', updated_at: 2.days.ago)
      newer = create(:game_purchase, game: game, comments: 'Newer review', updated_at: 1.day.ago)
      create(:game_purchase, game: game, comments: '')
      create(:game_purchase, game: other_game, comments: 'Different game')

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:game, :reviews, :total_count)).to eq(2)
      expect(result.graphql_dig(:game, :reviews, :nodes).pluck(:id)).to eq([newer.id.to_s, older.id.to_s])
    end

    it "sorts by rating, with unrated reviews last" do
      low = create(:game_purchase, game: game, comments: 'Meh', rating: 20)
      high = create(:game_purchase, game: game, comments: 'Great', rating: 90)
      unrated = create(:game_purchase, game: game, comments: 'No score')

      highest = api_request(query_string, variables: { id: game.id, sortBy: 'HIGHEST_RATING' }, token: access_token)
      lowest = api_request(query_string, variables: { id: game.id, sortBy: 'LOWEST_RATING' }, token: access_token)

      expect(highest.graphql_dig(:game, :reviews, :nodes).pluck(:id)).to eq([high, low, unrated].map { |gp| gp.id.to_s })
      expect(lowest.graphql_dig(:game, :reviews, :nodes).pluck(:id)).to eq([low, high, unrated].map { |gp| gp.id.to_s })
    end

    it "hides reviews from private and banned users" do
      visible = create(:game_purchase, game: game, user: user, comments: 'Visible')
      create(:game_purchase, game: game, user: private_user, comments: 'Private')
      create(:game_purchase, game: game, user: banned_user, comments: 'Banned')

      result = api_request(query_string, variables: { id: game.id }, token: access_token)

      expect(result.graphql_dig(:game, :reviews)).to eq(
        { totalCount: 1, nodes: [{ id: visible.id.to_s, comments: 'Visible', rating: nil, user: { id: user.id.to_s } }] }
      )
    end

    it "works without a logged-in user" do
      create(:game_purchase, game: game, comments: 'Anonymous can read this')

      result = api_request(query_string, variables: { id: game.id }, token: nil)

      expect(result.graphql_dig(:game, :reviews, :total_count)).to eq(1)
    end
  end
end
