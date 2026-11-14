# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataItemStatus do
  def stale(ids, chunk_size: described_class::CHUNK_SIZE, **items)
    fake = FakeWikidataItems.new(**items)
    allow(WikidataSparql).to receive(:query) { |sparql| fake.query(sparql) }
    described_class.new(chunk_size: chunk_size).stale(ids).transform_values(&:to_h)
  end

  it 'returns nothing when every item is fine' do
    expect(stale([1, 2, 3])).to eq({})
  end

  it 'reports a deleted item' do
    expect(stale([1, 2], deleted: [2])).to eq(2 => { wikidata_id: 2, state: :deleted, redirect_target: nil })
  end

  it 'reports a redirected item with its target' do
    expect(stale([1, 2], redirects: { 2 => 50 })).to eq(2 => { wikidata_id: 2, state: :redirected, redirect_target: 50 })
  end

  it 'does not count an item with a label but no statements as deleted' do
    expect(stale([1, 2], labels_only: [2])).to eq({})
  end

  it 'follows a redirect to its final target' do
    expect(stale([1], redirects: { 1 => 2, 2 => 3 })).to eq(1 => { wikidata_id: 1, state: :redirected, redirect_target: 3 })
  end

  it 'counts a redirect to a deleted item as deleted' do
    expect(stale([1], redirects: { 1 => 2 }, deleted: [2])).to eq(1 => { wikidata_id: 1, state: :deleted, redirect_target: nil })
  end

  it 'raises instead of trusting a chunk where most items look deleted' do
    ids = (1..10).to_a

    expect { stale(ids, deleted: ids.first(6)) }.to raise_error(described_class::SuspiciousResultError)
  end

  it 'allows a small chunk where most items are deleted' do
    expect(stale([1, 2], deleted: [1, 2]).keys).to eq([1, 2])
  end

  it 'queries in chunks' do
    fake = FakeWikidataItems.new(deleted: [5])
    allow(WikidataSparql).to receive(:query) { |sparql| fake.query(sparql) }

    result = described_class.new(chunk_size: 2).stale([1, 2, 3, 4, 5])

    expect(result.keys).to eq([5])
    # Three chunks, each a redirect query and a statement query, plus a label
    # query for the one chunk with an item that has no statements.
    expect(fake.queries.length).to eq(7)
  end
end
