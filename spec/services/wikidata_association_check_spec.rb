# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataAssociationCheck do
  # Fake Wikidata: `values` maps an item ID to { 'P400' => [value IDs], ... }.
  # Answers for whichever items are in the query's VALUES clause.
  def stub_wikidata(values)
    allow(WikidataSparql).to receive(:query) do |sparql|
      items = sparql[/VALUES \?item \{([^}]*)\}/, 1].scan(/wd:Q(\d+)/).flatten.map(&:to_i)
      items.flat_map do |item|
        values.fetch(item, {}).flat_map do |property, ids|
          ids.map do |id|
            { item: "http://www.wikidata.org/entity/Q#{item}", property: property, value: "http://www.wikidata.org/entity/Q#{id}" }
          end
        end
      end
    end
  end

  def results(**options)
    found = []
    described_class.new(**options).each_result { |result| found << result }
    found
  end

  it 'reports a platform Wikidata replaced with another one' do
    game = create(:game, name: 'Doom', wikidata_id: 100)
    wrong = create(:platform, name: 'Wrong Platform', wikidata_id: 500)
    right = create(:platform, wikidata_id: 501)
    create(:game_platform, game: game, platform: wrong)
    create(:game_platform, game: game, platform: right)
    stub_wikidata(100 => { 'P400' => [501, 502] })

    expect(results.map(&:to_h)).to eq(
      [
        {
          association: :platforms,
          game_id: game.id,
          game_name: 'Doom',
          game_wikidata_id: 100,
          record_id: wrong.id,
          record_name: 'Wrong Platform',
          record_wikidata_id: 500,
          wikidata_values: 2
        }
      ]
    )
  end

  it 'checks genres, engines, developers, publishers and series' do
    series = create(:series, wikidata_id: 600)
    game = create(:game, wikidata_id: 100, series: series)
    create(:game_genre, game: game, genre: create(:genre, wikidata_id: 601))
    create(:game_engine, game: game, engine: create(:engine, wikidata_id: 602))
    create(:game_developer, game: game, company: create(:company, wikidata_id: 603))
    create(:game_publisher, game: game, company: create(:company, wikidata_id: 604))
    stub_wikidata(100 => { 'P136' => [1], 'P408' => [1], 'P178' => [1], 'P123' => [1], 'P179' => [1] })

    expect(results.map { |result| [result.association, result.record_wikidata_id] }).to contain_exactly(
      [:genres, 601], [:engines, 602], [:developers, 603], [:publishers, 604], [:series, 600]
    )
  end

  it 'does not report associations Wikidata has' do
    game = create(:game, wikidata_id: 100, series: create(:series, wikidata_id: 600))
    create(:game_platform, game: game, platform: create(:platform, wikidata_id: 500))
    stub_wikidata(100 => { 'P400' => [500], 'P179' => [600] })

    expect(results).to be_empty
  end

  it 'skips properties the item has no values for unless include_empty is set' do
    game = create(:game, wikidata_id: 100)
    create(:game_platform, game: game, platform: create(:platform, wikidata_id: 500))
    stub_wikidata({})

    expect(results).to be_empty
    expect(results(include_empty: true).map { |result| [result.record_wikidata_id, result.wikidata_values] }).to eq([[500, 0]])
  end

  it 'only checks the given associations' do
    game = create(:game, wikidata_id: 100)
    create(:game_platform, game: game, platform: create(:platform, wikidata_id: 500))
    create(:game_genre, game: game, genre: create(:genre, wikidata_id: 600))
    stub_wikidata(100 => { 'P400' => [1], 'P136' => [1] })

    expect(results(associations: [:genres]).map(&:association)).to eq([:genres])
  end

  it 'rejects unknown associations' do
    expect { described_class.new(associations: [:stores]) }.to raise_error(ArgumentError, /stores/)
  end

  it 'leaves out deprecated statements in the query' do
    create(:game, wikidata_id: 100)
    stub_wikidata({})
    results

    expect(WikidataSparql).to have_received(:query).with(/FILTER\(\?rank != wikibase:DeprecatedRank\)/)
  end

  it 'queries Wikidata in chunks' do
    stub_const("#{described_class}::CHUNK_SIZE", 2)
    3.times { |i| create(:game, wikidata_id: 100 + i) }
    stub_wikidata({})

    results
    expect(WikidataSparql).to have_received(:query).twice
  end

  it 'never writes to the games' do
    game = create(:game, wikidata_id: 100)
    create(:game_platform, game: game, platform: create(:platform, wikidata_id: 500))
    stub_wikidata(100 => { 'P400' => [501] })

    expect { results }.not_to(change { [game.reload.attributes, game.platforms.pluck(:id)] })
  end
end
