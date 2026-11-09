# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataNameCheck do
  # WikidataSparql.query returns RDF solutions; the check reads `[:item]`,
  # `[:enLabel]` and `[:mulLabel]` off each row, so plain hashes stand in.
  def label_row(wikidata_id, english: nil, mul: nil)
    { item: "http://www.wikidata.org/entity/Q#{wikidata_id}", enLabel: english, mulLabel: mul }
  end

  def results(games: Game.all)
    found = []
    described_class.new(games: games).each_result { |result| found << result }
    found
  end

  it 'reports a game whose name differs from the en label' do
    game = create(:game, name: 'Portal 2 (video game)', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, english: 'Portal 2', mul: 'Portal II')])

    expect(results.map(&:to_h)).to eq(
      [
        {
          kind: :mismatch,
          game_id: game.id,
          wikidata_id: 100,
          game_name: 'Portal 2 (video game)',
          wikidata_label: 'Portal 2',
          label_language: 'en'
        }
      ]
    )
  end

  it 'falls back to the mul label when there is no en label' do
    create(:game, name: 'Tetris', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, mul: 'TETRIS')])

    expect(results.map { |result| [result.wikidata_label, result.label_language] }).to eq([['TETRIS', 'mul']])
  end

  it 'does not report a game that matches its label' do
    create(:game, name: 'Portal 2', wikidata_id: 100)
    create(:game, name: 'Tetris', wikidata_id: 101)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, english: 'Portal 2'), label_row(101, mul: 'Tetris')])

    expect(results).to be_empty
  end

  it 'counts differences in case' do
    create(:game, name: 'Doom', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, english: 'DOOM')])

    expect(results.map(&:kind)).to eq([:mismatch])
  end

  it 'ignores Unicode normalization differences and surrounding whitespace' do
    create(:game, name: "Pokémon Red ", wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, english: "Pokémon Red".unicode_normalize(:nfd))])

    expect(results).to be_empty
  end

  it 'reports an item with neither an en nor a mul label' do
    game = create(:game, name: 'Gone', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100)])

    expect(results.map { |result| [result.kind, result.game_id, result.wikidata_label] }).to eq([[:no_label, game.id, nil]])
  end

  it 'skips games without a Wikidata ID' do
    create(:game, name: 'No Wikidata', wikidata_id: nil)
    allow(WikidataSparql).to receive(:query).and_return([])

    expect(results).to be_empty
    expect(WikidataSparql).not_to have_received(:query)
  end

  it 'queries Wikidata in chunks' do
    stub_const("#{described_class}::CHUNK_SIZE", 2)
    3.times { |i| create(:game, name: "Game #{i}", wikidata_id: 100 + i) }
    allow(WikidataSparql).to receive(:query) do |sparql|
      sparql.scan(/wd:Q(\d+)/).flatten.map { |id| label_row(id, english: "Game #{id.to_i - 100}") }
    end

    expect(results).to be_empty
    expect(WikidataSparql).to have_received(:query).twice
  end

  it 'never writes to the games' do
    game = create(:game, name: 'Old Name', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([label_row(100, english: 'New Name')])

    expect { results }.not_to(change { game.reload.attributes })
  end
end
