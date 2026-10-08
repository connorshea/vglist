# frozen_string_literal: true

require 'rails_helper'

# The search page is public, so signed-out visitors (and browser address-bar
# searches) send its queries without a token. Those requests are held to the
# 500-point complexity limit that authenticated SPA requests skip, so run the
# frontend's actual query documents anonymously, at the page sizes it really
# uses, to keep them under it.
RSpec.describe "Search page queries", type: :request do
  tab_types = %w[games companies platforms series engines genres stores users]

  # Each `gql` template literal in the queries file, with `${FRAGMENT}`
  # interpolations replaced by the fragment documents they refer to.
  def documents
    source = Rails.root.join('frontend/src/graphql/queries/search.ts').read
    constants = source.scan(/const (\w+) = gql`(.*?)`;/m).to_h
    constants.transform_values do |body|
      body.gsub(/\$\{(\w+)\}/) { constants.fetch(Regexp.last_match(1)) }
    end
  end

  # The page sizes the search page passes as `first`.
  def page_size(type)
    source = Rails.root.join('frontend/src/utils/search.ts').read
    constant = type == 'games' ? 'GAMES_PAGE_SIZE' : 'PAGE_SIZE'
    Integer(source[/export const #{constant} = (\d+);/, 1])
  end

  def anonymous_request(document, variables)
    post graphql_path, params: { query: document, variables: variables.to_json }
    JSON.parse(response.body)
  end

  before(:each) do
    create(:game_with_everything, name: 'Ratatouille')
  end

  it "runs the overview query for signed-out visitors" do
    result = anonymous_request(documents.fetch('SEARCH_OVERVIEW'), { query: 'Ratatouille' })

    expect(result['errors']).to be_nil
    expect(result.dig('data', 'games', 'totalCount')).to eq(1)
  end

  tab_types.each do |type|
    it "runs the #{type} tab's query for signed-out visitors" do
      flags = tab_types.index_with { |t| t == type }
      variables = { query: 'Ratatouille', first: page_size(type), after: nil, **flags }

      result = anonymous_request(documents.fetch('SEARCH_TAB'), variables)

      expect(result['errors']).to be_nil
      expect(result['data'].keys).to eq([type])
    end
  end
end
