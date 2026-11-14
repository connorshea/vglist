# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'pg_search initializer' do # rubocop:disable RSpec/DescribeClass
  describe 'multisearch options' do
    it 'uses prefix tsearch only for queries shorter than four characters' do
      %w[e to the].each do |query|
        expect(VglistSearch.multisearch_options(query)).to eq(query: query, using: { tsearch: { prefix: true } })
      end
    end

    it 'ignores surrounding whitespace when measuring the query' do
      expect(VglistSearch.multisearch_options('  to  ')[:using]).to eq(tsearch: { prefix: true })
    end

    it 'uses tsearch and trigram for queries of four characters or more' do
      %w[tomb portal].each do |query|
        expect(VglistSearch.multisearch_options(query)).to eq(query: query, using: [:tsearch, :trigram])
      end
    end

    it 'keeps trigram matching out of the SQL for short queries' do
      expect(PgSearch.multisearch('to').to_sql).not_to include('%')
      expect(PgSearch.multisearch('tomb').to_sql).to include("'tomb' % ")
    end
  end
end
