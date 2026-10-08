# frozen_string_literal: true

require 'rails_helper'

# Behaviour shared by the per-type search fields (`gameSearch`,
# `companySearch`, ...), which all rank through the `Searchable` concern.
RSpec.describe "Per-type search API", type: :request do
  let(:user) { create(:confirmed_user) }
  let(:application) { build(:application, owner: user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

  def search(field, query, selection: 'id name')
    query_string = <<-GRAPHQL
      query($query: String!) {
        #{field}(query: $query) {
          totalCount
          nodes { #{selection} }
        }
      }
    GRAPHQL
    api_request(query_string, variables: { query: query }, token: access_token)
  end

  describe "matching and ranking" do
    it "matches typos" do
      game = create(:game, name: 'Ratatouille')

      expect(search('gameSearch', 'ratatoulie').graphql_dig(:game_search, :nodes).pluck(:id)).to eq([game.id.to_s])
    end

    it "ranks an exact match above a longer name" do
      longer = create(:game, name: 'Ratatouille: Food Frenzy')
      exact = create(:game, name: 'Ratatouille')

      ids = search('gameSearch', 'Ratatouille').graphql_dig(:game_search, :nodes).pluck(:id)

      expect(ids).to eq([exact.id.to_s, longer.id.to_s])
    end

    it "matches typos for every other searchable type" do
      {
        companySearch: create(:company, name: 'Nintendo'),
        platformSearch: create(:platform, name: 'Nintendo'),
        seriesSearch: create(:series, name: 'Nintendo'),
        engineSearch: create(:engine, name: 'Nintendo'),
        genreSearch: create(:genre, name: 'Nintendo'),
        storeSearch: create(:store, name: 'Nintendo')
      }.each do |field, record|
        nodes = search(field, 'nintedno').graphql_dig(field, :nodes)

        expect(nodes.pluck(:id)).to eq([record.id.to_s]), "#{field} didn't match the typo"
      end
    end
  end

  describe "banned users" do
    let!(:visible) { create(:confirmed_user, username: 'probeuser') }

    before(:each) do
      create(:confirmed_user, username: 'probeuser2', banned: true)
    end

    it "leaves them out of userSearch" do
      result = search('userSearch', 'probeuser', selection: 'id username').graphql_dig(:user_search)

      expect(result).to eq(totalCount: 1, nodes: [{ id: visible.id.to_s, username: 'probeuser' }])
    end

    it "leaves them out of globalSearch" do
      query_string = <<-GRAPHQL
        query($query: String!) {
          globalSearch(query: $query, searchableTypes: [USER]) {
            nodes { ... on SearchResultInterface { searchableId } }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: 'probeuser' }, token: access_token)

      expect(result.graphql_dig(:global_search, :nodes)).to eq([{ searchableId: visible.id.to_s }])
    end
  end

  describe "query validation" do
    it "rejects queries longer than 200 characters" do
      result = search('gameSearch', 'a' * 201)

      expect(api_result_errors(result)).to include(a_string_matching(/too long/i))
    end

    it "rejects null bytes instead of erroring" do
      result = search('gameSearch', "x\u0000y")

      expect(api_result_errors(result)).to include(a_string_matching(/null byte/i))
    end

    it "validates globalSearch queries the same way" do
      query_string = 'query($query: String!) { globalSearch(query: $query) { nodes { ... on SearchResultInterface { searchableId } } } }'

      result = api_request(query_string, variables: { query: 'a' * 201 }, token: access_token)

      expect(api_result_errors(result)).to include(a_string_matching(/too long/i))
    end
  end

  describe "gameSearch preloading" do
    let(:rows_query) do
      <<-GRAPHQL
        query($query: String!) {
          gameSearch(query: $query, first: 10) {
            nodes {
              id
              name
              releaseDate
              coverUrl(size: SMALL)
              isInLibrary
              platforms(first: 8) { totalCount nodes { id name } }
              developers(first: 3) { nodes { id name } }
              publishers(first: 3) { nodes { id name } }
              series { id name }
            }
          }
        }
      GRAPHQL
    end

    # Warm up with one request so one-off work (schema loading, Doorkeeper
    # lookups) doesn't count against the second.
    def warm_then_count_queries
      api_request(rows_query, variables: { query: 'Halo' }, token: access_token)
      query_count { api_request(rows_query, variables: { query: 'Halo' }, token: access_token) }
    end

    it "runs no more queries as the result list grows" do
      create_list(:game_with_everything, 2, name: 'Halo')
      baseline = warm_then_count_queries

      create_list(:game_with_everything, 4, name: 'Halo')

      expect(warm_then_count_queries).to eq(baseline)
    end
  end
end
