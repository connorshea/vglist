# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL public response cache", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:operations) { OperationAllowlist.operations }
  let(:user) { create(:confirmed_user) }
  let!(:game) { create(:game, name: 'Before') }

  let(:shelf_variables) do
    {
      first: 6,
      after: nil,
      sortBy: 'NEWEST',
      onPlatform: nil,
      byGenre: nil,
      byEngine: nil,
      fromYear: nil,
      toYear: nil,
      excludeLibrary: nil,
      withCount: false
    }
  end

  # The test environment uses a null store.
  around(:each) do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end

  def graphql(operation_name, variables: {}, query: operations.fetch(operation_name), token: nil)
    headers = token ? { 'Authorization': "Bearer #{token}" } : {}
    post graphql_path, params: { query: query, operationName: operation_name, variables: variables.to_json }, headers: headers
    JSON.parse(response.body)
  end

  def shelf_names(body)
    body.dig('data', 'games', 'nodes').pluck('name')
  end

  it "serves a signed-out home page shelf from the cache" do
    expect(shelf_names(graphql('GetGamesIndex', variables: shelf_variables))).to eq(['Before'])
    game.update!(name: 'After')
    expect(shelf_names(graphql('GetGamesIndex', variables: shelf_variables))).to eq(['Before'])
  end

  it "expires cached responses" do
    graphql('GetGamesIndex', variables: shelf_variables)
    game.update!(name: 'After')
    travel(PublicResponseCache::EXPIRES_IN + 1.second) do
      expect(shelf_names(graphql('GetGamesIndex', variables: shelf_variables))).to eq(['After'])
    end
  end

  it "doesn't cache game tiles for a signed-in user, whose library status they carry", :aggregate_failures do
    token = JwtService.encode(user)
    create(:game_purchase, user: user, game: game, completion_status: :completed)

    body = graphql('GetGamesIndex', variables: shelf_variables, token: token)
    expect(body.dig('data', 'games', 'nodes', 0, 'libraryCompletionStatus')).to eq('COMPLETED')

    # Neither served from nor written to the cache.
    signed_out = graphql('GetGamesIndex', variables: shelf_variables)
    expect(signed_out.dig('data', 'games', 'nodes', 0, 'isInLibrary')).to be_nil
    game.update!(name: 'After')
    expect(shelf_names(graphql('GetGamesIndex', variables: shelf_variables, token: token))).to eq(['After'])
  end

  describe "the new releases shelf" do
    before(:each) { game.update!(release_date: 1.day.ago) }

    def new_release_names(body)
      body.dig('data', 'newReleases').pluck('name')
    end

    it "serves it from the cache when signed out" do
      expect(new_release_names(graphql('GetNewReleases', variables: { first: 6 }))).to eq(['Before'])
      game.update!(name: 'After')
      expect(new_release_names(graphql('GetNewReleases', variables: { first: 6 }))).to eq(['Before'])
    end

    it "doesn't cache it for a signed-in user" do
      token = JwtService.encode(user)
      graphql('GetNewReleases', variables: { first: 6 }, token: token)
      game.update!(name: 'After')
      expect(new_release_names(graphql('GetNewReleases', variables: { first: 6 }, token: token))).to eq(['After'])
    end
  end

  describe "the upcoming releases shelf" do
    before(:each) { game.update!(release_date: 1.week.from_now) }

    def upcoming_release_names(body)
      body.dig('data', 'upcomingReleases').pluck('name')
    end

    it "serves it from the cache when signed out" do
      expect(upcoming_release_names(graphql('GetUpcomingReleases', variables: { first: 6 }))).to eq(['Before'])
      game.update!(name: 'After')
      expect(upcoming_release_names(graphql('GetUpcomingReleases', variables: { first: 6 }))).to eq(['Before'])
    end

    it "doesn't cache it for a signed-in user" do
      token = JwtService.encode(user)
      graphql('GetUpcomingReleases', variables: { first: 6 }, token: token)
      game.update!(name: 'After')
      expect(upcoming_release_names(graphql('GetUpcomingReleases', variables: { first: 6 }, token: token))).to eq(['After'])
    end
  end

  it "caches the hero covers for signed-in users too" do
    graphql('GetHeroCovers', token: JwtService.encode(user))
    expect(Rails.cache.exist?(PublicResponseCache.key_for(operations['GetHeroCovers'], 'GetHeroCovers', {}, user))).to be(true)
  end

  it "doesn't cache filtered or later pages of games" do
    graphql('GetGamesIndex', variables: shelf_variables.merge(fromYear: 2000))
    graphql('GetGamesIndex', variables: shelf_variables.merge(after: 'MQ'))
    game.update!(name: 'After')
    expect(shelf_names(graphql('GetGamesIndex', variables: shelf_variables.merge(fromYear: nil, after: nil)))).to eq(['After'])
  end

  it "doesn't cache a different document sent under a cached operation's name" do
    query = 'query GetHeroCovers { games(first: 1) { nodes { name } } }'
    graphql('GetHeroCovers', query: query)
    game.update!(name: 'After')
    expect(graphql('GetHeroCovers', query: query).dig('data', 'games', 'nodes', 0, 'name')).to eq('After')
  end

  it "doesn't cache errors" do
    allow(VideoGameListSchema).to receive(:execute).and_return({ 'data' => nil, 'errors' => [{ 'message' => 'Timeout' }] })
    graphql('GetHeroCovers')
    expect(Rails.cache.exist?(PublicResponseCache.key_for(operations['GetHeroCovers'], 'GetHeroCovers', {}, nil))).to be(false)
  end
end
