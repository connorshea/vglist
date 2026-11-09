# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Game moreFromSeries API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }
  let(:series) { create(:series) }
  let(:query_string) do
    <<-GRAPHQL
      query($id: ID!) {
        game(id: $id) {
          moreFromSeries(first: 3) {
            nodes { id }
            totalCount
          }
        }
      }
    GRAPHQL
  end

  def more_from_series(game)
    result = api_request(query_string, variables: { id: game.id }, token: access_token)
    result.graphql_dig(:game, :moreFromSeries)
  end

  it "returns the series' other games, most owned first" do
    game = create(:game, series: series)
    niche = create(:game, series: series, release_date: Date.new(1990, 1, 1), game_purchases_count: 2)
    popular = create(:game, series: series, release_date: Date.new(2010, 1, 1), game_purchases_count: 50)
    middling = create(:game, series: series, release_date: Date.new(2000, 1, 1), game_purchases_count: 10)

    expect(more_from_series(game)[:nodes]).to eq([popular, middling, niche].map { |g| { id: g.id.to_s } })
  end

  it "breaks owner count ties by release date, undated games last" do
    game = create(:game, series: series, release_date: Date.new(2004, 11, 16))
    undated = create(:game, series: series, release_date: nil)
    later = create(:game, series: series, release_date: Date.new(2007, 10, 10))
    earlier = create(:game, series: series, release_date: Date.new(1998, 11, 19))
    create(:game, series: create(:series), release_date: Date.new(2000, 1, 1))

    expect(more_from_series(game)).to eq(
      nodes: [earlier, later, undated].map { |g| { id: g.id.to_s } },
      totalCount: 3
    )
  end

  it "breaks owner count and release date ties by id" do
    game = create(:game, series: series)
    first = create(:game, series: series, release_date: Date.new(2010, 1, 1))
    second = create(:game, series: series, release_date: Date.new(2010, 1, 1))

    expect(more_from_series(game)[:nodes]).to eq([first, second].map { |g| { id: g.id.to_s } })
  end

  it "limits the list but counts every other game in the series" do
    game = create(:game, series: series)
    create_list(:game, 4, series: series)

    result = more_from_series(game)

    expect(result[:nodes].length).to eq(3)
    expect(result[:totalCount]).to eq(4)
  end

  it "is empty when the game is the only one in its series" do
    game = create(:game, series: series)

    expect(more_from_series(game)).to eq(nodes: [], totalCount: 0)
  end

  it "is empty when the game has no series" do
    game = create(:game)
    create(:game, series: series)

    expect(more_from_series(game)).to eq(nodes: [], totalCount: 0)
  end
end
