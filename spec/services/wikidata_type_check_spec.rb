# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataTypeCheck do
  # WikidataSparql.query returns RDF solutions; the check reads `[:item]`,
  # `[:class]` and `[:classLabel]` off each row, so plain hashes stand in.
  def class_row(wikidata_id, class_id, label = nil)
    { item: "http://www.wikidata.org/entity/Q#{wikidata_id}", class: "http://www.wikidata.org/entity/Q#{class_id}", classLabel: label }
  end

  def results(games: Game.all)
    found = []
    described_class.new(games: games).each_result { |result| found << result }
    found
  end

  it 'reports a game whose item is no longer a video game' do
    game = create(:game, name: 'Some Expansion', wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return(
      [class_row(100, 1_066_707, 'downloadable content'), class_row(100, 209_163, 'expansion pack')]
    )

    expect(results.map(&:to_h)).to eq(
      [
        {
          kind: :not_a_video_game,
          game_id: game.id,
          wikidata_id: 100,
          game_name: 'Some Expansion',
          owners: 0,
          instance_of: 'Q209163 (expansion pack); Q1066707 (downloadable content)'
        }
      ]
    )
  end

  it 'does not report a video game or a free or open source video game' do
    create(:game, wikidata_id: 100)
    create(:game, wikidata_id: 101)
    allow(WikidataSparql).to receive(:query).and_return(
      [class_row(100, 7889, 'video game'), class_row(100, 1_066_707), class_row(101, 21_125_433)]
    )

    expect(results).to be_empty
  end

  it 'reports an item with no instance of at all' do
    game = create(:game, wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([])

    expect(results.map { |result| [result.kind, result.game_id, result.instance_of] }).to eq([[:no_instance_of, game.id, '']])
  end

  it 'lists a class without an English label by its ID' do
    create(:game, wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([class_row(100, 11_424)])

    expect(results.map(&:instance_of)).to eq(['Q11424'])
  end

  it 'includes the number of owners' do
    game = create(:game, wikidata_id: 100)
    create_list(:game_purchase, 2, game: game)
    allow(WikidataSparql).to receive(:query).and_return([class_row(100, 11_424, 'film')])

    expect(results.map(&:owners)).to eq([2])
  end

  it 'skips games without a Wikidata ID' do
    create(:game, wikidata_id: nil)
    allow(WikidataSparql).to receive(:query).and_return([])

    expect(results).to be_empty
    expect(WikidataSparql).not_to have_received(:query)
  end

  it 'queries Wikidata in chunks' do
    stub_const("#{described_class}::CHUNK_SIZE", 2)
    3.times { |i| create(:game, wikidata_id: 100 + i) }
    allow(WikidataSparql).to receive(:query) do |sparql|
      sparql.scan(/wd:Q(\d+)/).flatten.map { |id| class_row(id, 7889) }
    end

    expect(results).to be_empty
    expect(WikidataSparql).to have_received(:query).twice
  end

  it 'never writes to the games' do
    game = create(:game, wikidata_id: 100)
    allow(WikidataSparql).to receive(:query).and_return([class_row(100, 11_424, 'film')])

    expect { results }.not_to(change { game.reload.attributes })
  end
end
