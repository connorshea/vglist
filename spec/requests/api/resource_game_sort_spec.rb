# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Sorting the games on a resource", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }
  let(:platform) { create(:platform) }

  # Three games with different release dates, owner counts, ratings and names,
  # plus one with none of those, which every sort must still include.
  let!(:old_popular) { create(:game, name: 'Bravo', release_date: Date.new(2001, 1, 1)) }
  let!(:new_unpopular) { create(:game, name: 'Charlie', release_date: Date.new(2020, 1, 1)) }
  let!(:unreleased) { create(:game, name: 'Alpha', release_date: 1.year.from_now.to_date) }
  let!(:bare) { create(:game, name: 'Delta', release_date: nil) }

  before(:each) do
    [old_popular, new_unpopular, unreleased, bare].each { |game| create(:game_platform, game: game, platform: platform) }
    create_list(:game_purchase, 2, game: old_popular)
    create(:game_purchase, game: unreleased)
    # Set after the purchases, since adding one recalculates the average rating.
    old_popular.update!(avg_rating: 60.0)
    new_unpopular.update!(avg_rating: 90.0)
    unreleased.update!(avg_rating: nil)
    bare.update!(avg_rating: nil)
  end

  def platform_game_names(sort_by)
    query_string = <<-GRAPHQL
      query($id: ID!, $sortBy: ResourceGameSort) {
        platform(id: $id) {
          games(sortBy: $sortBy) {
            totalCount
            nodes { name }
          }
        }
      }
    GRAPHQL

    result = api_request(query_string, variables: { id: platform.id, sort_by: sort_by }, token: access_token)
    expect(result.graphql_dig(:platform, :games, :total_count)).to eq(4)
    result.graphql_dig(:platform, :games, :nodes).pluck(:name)
  end

  it "sorts by newest release, with unreleased games first and undated games last" do
    expect(platform_game_names('NEWEST_RELEASE')).to eq(%w[Alpha Charlie Bravo Delta])
  end

  it "sorts by most owners" do
    expect(platform_game_names('MOST_OWNERS')).to eq(%w[Bravo Alpha Delta Charlie])
  end

  it "sorts by highest rating, with unrated games last" do
    expect(platform_game_names('HIGHEST_RATED')).to eq(%w[Charlie Bravo Delta Alpha])
  end

  it "sorts by name" do
    expect(platform_game_names('NAME')).to eq(%w[Alpha Bravo Charlie Delta])
  end

  it "orders by ID when no sort is given, so pages don't overlap" do
    expect(platform_game_names(nil)).to eq(%w[Bravo Charlie Alpha Delta])
    expect(ResourceGameSort.apply(platform.games, nil).to_sql).to end_with('ORDER BY games.id ASC')
  end

  it "sorts a company's developed and published games independently" do
    company = create(:company)
    create(:game_developer, game: old_popular, company: company)
    create(:game_developer, game: new_unpopular, company: company)
    create(:game_publisher, game: bare, company: company)
    create(:game_publisher, game: unreleased, company: company)

    query_string = <<-GRAPHQL
      query($id: ID!) {
        company(id: $id) {
          developedGames(sortBy: NEWEST_RELEASE) { nodes { name } }
          publishedGames(sortBy: NAME) { nodes { name } }
        }
      }
    GRAPHQL

    result = api_request(query_string, variables: { id: company.id }, token: access_token)

    expect(result.graphql_dig(:company, :developed_games, :nodes).pluck(:name)).to eq(%w[Charlie Bravo])
    expect(result.graphql_dig(:company, :published_games, :nodes).pluck(:name)).to eq(%w[Alpha Delta])
  end
end
