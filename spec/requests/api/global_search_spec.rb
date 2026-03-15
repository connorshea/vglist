require 'rails_helper'

RSpec.describe "Global Search API", type: :request do
  describe "Query for data" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }

    context 'with games' do
      let(:game1) { create(:game, name: 'Half-Life') }
      let(:game2) { create(:game_with_cover, name: 'Super Mario Galaxy', developers: create_list(:company, 1, name: 'Nintendo'), release_date: 1.day.ago) }
      let(:games) { create_list(:game, 10, name: 'Portal') }

      it "returns basic data" do
        game1
        games
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              nodes {
                ... on GameSearchResult {
                  id
                  searchableId
                  content
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Portal' }, token: access_token)

        expect(result.graphql_dig(:global_search, :nodes).length).to eq(10)
        expect(result.graphql_dig(:global_search, :nodes).pluck(:searchableId)).to eq(games.pluck(:id).map(&:to_s))
        expect(result.graphql_dig(:global_search, :nodes).pluck(:content)).to eq(Array.new(10) { 'Portal' })
      end

      it "returns cover, release date, and developer" do
        game2
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              nodes {
                ... on GameSearchResult {
                  searchableId
                  content
                  coverUrl
                  releaseDate
                  developerName
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Super Mario Gala' }, token: access_token)

        cover_variant = game2.sized_cover(:small)

        expect(result.graphql_dig(:global_search, :nodes)).to eq(
          [
            {
              searchableId: game2.id.to_s,
              content: 'Super Mario Galaxy',
              coverUrl: Rails.application.routes.url_helpers.rails_representation_url(cover_variant),
              releaseDate: 1.day.ago.strftime("%F"),
              developerName: 'Nintendo'
            }
          ]
        )
      end
    end

    context 'with users' do
      let!(:user) { create(:user_with_avatar, username: 'among.us.fan') }

      it "returns avatar and slug" do
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              nodes {
                ... on UserSearchResult {
                  searchableId
                  content
                  avatarUrl
                  slug
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'among' }, token: access_token)

        avatar_variant = user.sized_avatar(:small)

        expect(result.graphql_dig(:global_search, :nodes)).to eq(
          [
            {
              searchableId: user.id.to_s,
              content: 'among.us.fan',
              avatarUrl: Rails.application.routes.url_helpers.rails_representation_url(avatar_variant),
              slug: 'among-us-fan'
            }
          ]
        )
      end
    end

    context 'when filtering by searchableTypes' do
      let!(:game) { create(:game, name: 'Searchable') }
      let!(:company) { create(:company, name: 'Searchable') }
      let!(:platform) { create(:platform, name: 'Searchable') }

      it "returns only the requested types" do
        query_string = <<-GRAPHQL
          query($query: String!, $types: [SearchableEnum!]) {
            globalSearch(query: $query, searchableTypes: $types) {
              nodes {
                ... on GameSearchResult {
                  searchableId
                  content
                }
                ... on CompanySearchResult {
                  searchableId
                  content
                }
                ... on PlatformSearchResult {
                  searchableId
                  content
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Searchable', types: ['GAME', 'COMPANY'] }, token: access_token)
        nodes = result.graphql_dig(:global_search, :nodes)

        expect(nodes.length).to eq(2)
        searchable_ids = nodes.pluck(:searchableId)
        expect(searchable_ids).to include(game.id.to_s, company.id.to_s)
        expect(searchable_ids).not_to include(platform.id.to_s)
      end

      it "returns only a single type when one is specified" do
        query_string = <<-GRAPHQL
          query($query: String!, $types: [SearchableEnum!]) {
            globalSearch(query: $query, searchableTypes: $types) {
              nodes {
                ... on PlatformSearchResult {
                  searchableId
                  content
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Searchable', types: ['PLATFORM'] }, token: access_token)
        nodes = result.graphql_dig(:global_search, :nodes)

        expect(nodes.length).to eq(1)
        expect(nodes.first[:searchableId]).to eq(platform.id.to_s)
      end
    end

    context 'with per-type result limits' do
      it "caps results at 25 per type to ensure type diversity" do
        create_list(:genre, 30, name: 'PerTypeCap')

        query_string = <<-GRAPHQL
          query($query: String!, $types: [SearchableEnum!]) {
            globalSearch(query: $query, searchableTypes: $types, first: 50) {
              totalCount
              nodes {
                ... on GenreSearchResult {
                  searchableId
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'PerTypeCap', types: ['GENRE'] }, token: access_token)

        expect(result.graphql_dig(:global_search, :total_count)).to eq(25)
        expect(result.graphql_dig(:global_search, :nodes).length).to eq(25)
      end

      it "returns results from multiple types even when one type has many matches" do
        create_list(:game, 30, name: 'Diverse')
        create(:company, name: 'Diverse')
        create(:platform, name: 'Diverse')

        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query, first: 50) {
              nodes {
                ... on GameSearchResult {
                  searchableId
                  searchableType
                }
                ... on CompanySearchResult {
                  searchableId
                  searchableType
                }
                ... on PlatformSearchResult {
                  searchableId
                  searchableType
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Diverse' }, token: access_token)
        nodes = result.graphql_dig(:global_search, :nodes)
        types = nodes.pluck(:searchableType).uniq

        # All three types should be represented despite games having 30 matches
        expect(types).to include('GAME', 'COMPANY', 'PLATFORM')
        # Games should be capped at 25
        game_count = nodes.count { |n| n[:searchableType] == 'GAME' }
        expect(game_count).to eq(25)
        # Total should be 25 games + 1 company + 1 platform = 27
        expect(nodes.length).to eq(27)
      end
    end

    context 'with all types of records' do
      let!(:company) { create(:company, name: 'Foo') }
      let!(:engine) { create(:engine, name: 'Foo') }
      let!(:game) { create(:game, name: 'Foo') }
      let!(:genre) { create(:genre, name: 'Foo') }
      let!(:platform) { create(:platform, name: 'Foo') }
      let!(:series) { create(:series, name: 'Foo') }
      let!(:user) { create(:user, username: 'Foo') }

      it "returns basic data" do
        query_string = <<-GRAPHQL
          query($query: String!) {
            globalSearch(query: $query) {
              nodes {
                ... on GameSearchResult {
                  searchableId
                  content
                }
                ... on UserSearchResult {
                  searchableId
                  content
                }
                ... on PlatformSearchResult {
                  searchableId
                  content
                }
                ... on SeriesSearchResult {
                  searchableId
                  content
                }
                ... on GenreSearchResult {
                  searchableId
                  content
                }
                ... on EngineSearchResult {
                  searchableId
                  content
                }
                ... on CompanySearchResult {
                  searchableId
                  content
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: 'Foo' }, token: access_token)

        nodes = result.graphql_dig(:global_search, :nodes)
        expect(nodes.length).to eq(7)
        expect(nodes).to include(
          { searchableId: company.id.to_s, content: company.name },
          { searchableId: engine.id.to_s, content: engine.name },
          { searchableId: game.id.to_s, content: game.name },
          { searchableId: genre.id.to_s, content: genre.name },
          { searchableId: platform.id.to_s, content: platform.name },
          { searchableId: series.id.to_s, content: series.name },
          { searchableId: user.id.to_s, content: user.username }
        )
      end
    end
  end
end
