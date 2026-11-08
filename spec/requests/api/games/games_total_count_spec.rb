# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "games totalCount", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }
  let(:access_token) { JwtService.encode(user) }
  let(:platform) { create(:platform) }

  let(:query_string) do
    <<-GRAPHQL
      query($sortBy: GameSort, $onPlatform: ID) {
        games(sortBy: $sortBy, onPlatform: $onPlatform) {
          totalCount
        }
      }
    GRAPHQL
  end

  before(:each) { create_list(:game, 3) }

  # The test environment uses a null store.
  around(:each) do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end

  def total_count(**variables)
    api_request(query_string, variables: variables, token: access_token).graphql_dig(:games, :total_count)
  end

  it "caches the count of an unfiltered list" do
    expect(total_count).to eq(3)
    create(:game)
    expect(total_count).to eq(3)
  end

  it "expires the cached count" do
    expect(total_count).to eq(3)
    create(:game)
    travel(CachedRowCount::EXPIRES_IN + 1.second) do
      expect(total_count).to eq(4)
    end
  end

  it "shares the cached count between unfiltered sorts, including grouped ones", :aggregate_failures do
    expect(total_count(sortBy: 'NEWEST')).to eq(3)
    create(:game)
    expect(total_count(sortBy: 'MOST_OWNERS')).to eq(3)
    expect(total_count(sortBy: 'MOST_FAVORITES')).to eq(3)
  end

  it "counts sorts that leave games out exactly" do
    expect(total_count).to eq(3)
    create(:game, release_date: 1.year.ago)
    expect(total_count(sortBy: 'RECENTLY_RELEASED')).to eq(1)
  end

  it "counts filtered lists exactly" do
    expect(total_count).to eq(3)
    create(:game_platform, game: create(:game), platform: platform)
    expect(total_count(onPlatform: platform.id)).to eq(1)
  end

  it "counts an association's games exactly, not the whole table" do
    genre = create(:genre)
    create(:game_genre, game: create(:game), genre: genre)
    genre_query = <<-GRAPHQL
      query($id: ID!) {
        genre(id: $id) {
          games {
            totalCount
          }
        }
      }
    GRAPHQL

    expect(total_count).to eq(4)
    result = api_request(genre_query, variables: { id: genre.id }, token: access_token)
    expect(result.graphql_dig(:genre, :games, :total_count)).to eq(1)
  end
end
