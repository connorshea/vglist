# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL complexity and depth limits", type: :request do
  # The largest `first` the SPA passes to each operation. Anything not listed
  # is checked at the maximum page size, 100.
  let(:spa_page_sizes) do
    Hash.new(100).merge(
      # HomePage.vue
      'GetRecentGames' => 6,
      # UserLibraryPage.vue: each status' shelf shows its first 12 games.
      'GetLibraryShelves' => 12,
      # GameFormPage.vue loads whole lists of resources for its pickers.
      'GetPlatforms' => 500,
      'GetCompanies' => 500,
      'GetGenres' => 500,
      'GetEngines' => 500,
      'GetSeriesList' => 500,
      # SeriesListPage.vue loads 24 series at a time, each with 4 covers.
      'GetSeriesIndex' => 24
    )
  end

  def analyze(document, variables = {})
    query = GraphQL::Query.new(VideoGameListSchema, document, variables: variables)
    complexity, depth = GraphQL::Analysis.analyze_query(
      query,
      [GraphQL::Analysis::QueryComplexity, GraphQL::Analysis::QueryDepth]
    )
    { complexity: complexity, depth: depth }
  end

  it 'fits every operation the SPA sends, at the page sizes it requests' do
    over_limit = OperationAllowlist.operations.filter_map do |name, document|
      variable_definitions = GraphQL.parse(document).definitions.first.variables
      variables = {}
      variables['first'] = spa_page_sizes[name] if variable_definitions.any? { |v| v.name == 'first' }
      # Score the worst case for `@include(if: $flag)` fields: all of them included.
      variable_definitions.each do |v|
        variables[v.name] = true if v.type.is_a?(GraphQL::Language::Nodes::NonNullType) && v.type.of_type.name == 'Boolean'
      end
      result = analyze(document, variables)

      next if result[:complexity] <= VideoGameListSchema.max_complexity && result[:depth] <= VideoGameListSchema.max_depth

      "#{name}: #{result}"
    end

    expect(over_limit).to be_empty
  end

  it 'scores short association lists as ~10 records' do
    query = '{ games(first: 10) { nodes { platforms(first: 100) { nodes { id } } } } }'

    # 10 games * (1 + 10 platforms * (nodes + id)) + games + nodes
    expect(analyze(query)[:complexity]).to eq(10 * (1 + (10 * 2)) + 2)
  end

  it 'scores short association lists with a smaller `first` by that size' do
    query = '{ games(first: 10) { nodes { developers(first: 3) { nodes { id } } } } }'

    expect(analyze(query)[:complexity]).to eq(10 * (1 + (3 * 2)) + 2)
  end

  it 'rejects an over-complex query from a signed-in user' do
    user = create(:confirmed_user)
    query = '{ games(first: 100) { nodes { owners(first: 100) { nodes { gamePurchases(first: 100) { nodes { id } } } } } } }'

    post graphql_path,
      params: { query: query }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{JwtService.encode(user)}" }

    expect(response.parsed_body['errors'].first['message']).to match(/exceeds max complexity/)
    expect(response.parsed_body['data']).to be_nil
  end

  describe 'negative page sizes' do
    def execute(query)
      VideoGameListSchema.execute(query).to_h['errors']&.pluck('message')
    end

    it 'rejects a negative `first` on a top-level connection' do
      expect(execute('{ games(first: -100000) { nodes { id } } }')).to include(/can't be negative/)
    end

    it 'rejects a negative `first` on a short association list' do
      expect(execute('{ games(first: 2) { nodes { platforms(first: -100000) { nodes { id } } } } }')).to include(/can't be negative/)
    end

    it 'rejects a negative `last`' do
      expect(execute('{ games(last: -5) { nodes { id } } }')).to include(/can't be negative/)
    end

    it 'never scores a short association list below zero' do
      query = '{ games(first: 10) { nodes { platforms(first: -100) { nodes { id } } } } }'

      expect(analyze(query)[:complexity]).to eq(10 * 1 + 2)
    end
  end
end
