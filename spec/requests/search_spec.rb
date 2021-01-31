# typed: false
require 'rails_helper'

RSpec.describe "Search", type: :request do
  describe "GET search_path" do
    let(:series) { create(:series) }
    let(:game) { create(:game) }
    let(:sequential_games) { create_list(:game, 15, :sequential_name) }
    let(:more_sequential_games) { create_list(:game, 20, :sequential_name) }
    let(:user1) { create(:user, username: 'foo.bar') }
    let(:user2) { create(:user, username: 'BazQux') }

    it "returns the given series" do
      get search_path(query: series.name, format: :json)
      expected_response = { searchable_id: series.id, content: series.name, searchable_type: 'Series' }
      expect(searchable_helper(response.body, 'Series')).to include(expected_response)
    end

    it "returns no item when given a random string" do
      sequential_games
      get search_path(query: SecureRandom.alphanumeric(16), format: :json)
      expected_response = {}
      %w[Game Series Company Platform Engine Genre User].each do |type|
        expected_response[type] = []
      end
      expect(response.body).to eq(expected_response.to_json)
    end

    it "returns no items when no query is given" do
      get search_path(format: :json)
      expected_response = {}
      %w[Game Series Company Platform Engine Genre User].each do |type|
        expected_response[type] = []
      end
      expect(response.body).to eq(expected_response.to_json)
    end

    it "returns game when a query is given" do
      get search_path(query: game.name, format: :json)
      expected_response = { searchable_id: game.id, content: game.name, searchable_type: 'Game' }
      expect(searchable_helper(response.body, 'Game')).to include(expected_response)
    end

    it "returns games when a query is given and multiple games with similar names exist" do
      sequential_games
      get search_path(query: "Game Name", format: :json)
      expected_response = { searchable_id: sequential_games.first.id, content: sequential_games.first.name, searchable_type: 'Game' }
      expect(searchable_helper(response.body, 'Game')).to include(expected_response)
    end

    it "returns games when using only games parameter and paginating" do
      more_sequential_games
      get search_path(query: "Game Name", only_games: true, page: 2, format: :json)
      expected_response = { searchable_id: more_sequential_games[15].id, content: more_sequential_games[15].name, searchable_type: 'Game' }
      not_expected_response = { searchable_id: more_sequential_games.first.id, content: more_sequential_games.first.name, searchable_type: 'Game' }
      # Include the 16th game in the sequential list but not the first, since
      # we're on page 2.
      expect(searchable_helper(response.body, 'Game')).to include(expected_response)
      expect(searchable_helper(response.body, 'Game')).not_to include(not_expected_response)
      # Only return games when only_games parameter is used.
      expect(JSON.parse(response.body).keys).not_to include(['Series', 'Platform', 'Company', 'User', 'Genre', 'Engine'])
    end

    it "returns correct user information when username has a period" do
      user1
      get search_path(query: "foo", format: :json)
      expected_response = { searchable_id: user1.id, content: user1.username, searchable_type: 'User', slug: 'foo-bar' }
      expect(searchable_helper(response.body, 'User', expected_response.keys)).to include(expected_response)
    end

    it "returns correct user information when username has capital letters" do
      user2
      get search_path(query: "baz", format: :json)
      expected_response = { searchable_id: user2.id, content: user2.username, searchable_type: 'User', slug: 'bazqux' }
      expect(searchable_helper(response.body, 'User', expected_response.keys)).to include(expected_response)
    end
  end
end
