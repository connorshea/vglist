# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataParentheticalNameRefreshService, type: :service do
  # The service reads `[:item]`/`[:label]` off each row, so plain hashes stand
  # in for the RDF solutions WikidataSparql.query returns.
  def stub_labels(labels)
    rows = labels.map { |id, label| { item: "http://www.wikidata.org/entity/Q#{id}", label: label } }
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  def service(dry_run: false)
    described_class.new(dry_run: dry_run)
  end

  describe 'PARENTHETICAL' do
    [
      'Doom (game)',
      'Doom (video game)',
      'Doom (2016 video game)',
      'Doom (1993 game)',
      'Doom (Video Game)',
      'Mario (video game series)',
      'Mario (game series)',
      'Mario (series)',
      'Mario (video game franchise)'
    ].each do |name|
      it "matches #{name.inspect}" do
        expect(name).to match(described_class::PARENTHETICAL)
      end
    end

    [
      'Doom',
      'Sonic the Hedgehog (Game Gear)',
      'Doom (video game) Remastered',
      'Final Fantasy VII (PC)'
    ].each do |name|
      it "doesn't match #{name.inspect}" do
        expect(name).not_to match(described_class::PARENTHETICAL)
      end
    end
  end

  describe '.candidates' do
    it 'finds games whose name ends in a disambiguator, with or without a Wikidata ID' do
      linked = create(:game, name: 'Doom (2016 video game)', wikidata_id: 1)
      unlinked = create(:game, name: 'Ranch (game)', wikidata_id: nil)
      create(:game, name: 'Doom', wikidata_id: 2)
      create(:game, name: 'Sonic the Hedgehog (Game Gear)', wikidata_id: 3)

      expect(described_class.candidates(Game)).to contain_exactly(linked, unlinked)
    end

    it 'finds series whose name ends in a disambiguator' do
      series = create(:series, name: 'Mario (video game series)')
      create(:series, name: 'Mario')

      expect(described_class.candidates(Series)).to contain_exactly(series)
    end

    it 'matches the same names as PARENTHETICAL' do
      names = ['Doom (GAME)', 'Doom (1993 video game)', 'Doom (video game) 2', 'Doom (Game Boy)']
      games = names.map.with_index { |name, i| create(:game, name: name, wikidata_id: i + 1) }

      expect(described_class.candidates(Game)).to match_array(games.select { |g| g.name.match?(described_class::PARENTHETICAL) })
    end

    it 'limits to a range of IDs' do
      games = Array.new(3) { |i| create(:game, name: "Game #{i} (video game)", wikidata_id: i + 1) }

      expect(described_class.candidates(Game, min_id: games[1].id, max_id: games[1].id)).to contain_exactly(games[1])
      expect(described_class.candidates(Game, min_id: games[1].id)).to contain_exactly(games[1], games[2])
      expect(described_class.candidates(Game, max_id: games[1].id)).to contain_exactly(games[0], games[1])
    end
  end

  describe '#call' do
    it 'updates game names that differ from the English label' do
      game = create(:game, name: 'Doom (2016 video game)', wikidata_id: 20_311_154)
      stub_labels(20_311_154 => 'Doom')

      results = []
      counts = service.call(described_class.candidates(Game)) { |result| results << result }

      expect(game.reload.name).to eq('Doom')
      expect(counts).to eq(updated: 1)
      expect(results.first).to have_attributes(old_name: 'Doom (2016 video game)', new_name: 'Doom', status: :updated)
    end

    it 'updates series names that differ from the English label' do
      series = create(:series, name: 'Mario (video game series)', wikidata_id: 1)
      stub_labels(1 => 'Mario')

      expect(service.call(described_class.candidates(Series))).to eq(updated: 1)
      expect(series.reload.name).to eq('Mario')
    end

    it 'records the rename in the version history', versioning: true do
      game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
      stub_labels(1 => 'Doom')

      expect { service.call(described_class.candidates(Game)) }.to change { game.versions.count }.by(1)
    end

    it 'leaves names that already match alone' do
      game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
      stub_labels(1 => 'Doom (video game)')

      expect(service.call(described_class.candidates(Game))).to eq(unchanged: 1)
      expect(game.reload.name).to eq('Doom (video game)')
    end

    it 'does not save anything in a dry run' do
      game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
      stub_labels(1 => 'Doom')

      expect(service(dry_run: true).call(described_class.candidates(Game))).to eq(updated: 1)
      expect(game.reload.name).to eq('Doom (video game)')
    end

    it 'skips records without a Wikidata ID and leaves them out of the query' do
      create(:game, name: 'Doom (video game)', wikidata_id: 1)
      unlinked = create(:game, name: 'Ranch (game)', wikidata_id: nil)
      stub_labels(1 => 'Doom')

      results = []
      counts = service.call(described_class.candidates(Game)) { |result| results << result }

      expect(counts).to eq(updated: 1, no_wikidata_id: 1)
      expect(results.find { |r| r.record == unlinked }).to have_attributes(status: :no_wikidata_id, old_name: 'Ranch (game)')
      expect(WikidataSparql).to have_received(:query).once.with(a_string_including('VALUES ?item { wd:Q1 }'))
    end

    it "doesn't query Wikidata when no record in the batch has a Wikidata ID" do
      create(:game, name: 'Ranch (game)', wikidata_id: nil)
      allow(WikidataSparql).to receive(:query)

      expect(service.call(described_class.candidates(Game))).to eq(no_wikidata_id: 1)
      expect(WikidataSparql).not_to have_received(:query)
    end

    it 'skips items with no English label' do
      game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
      stub_labels({})

      expect(service.call(described_class.candidates(Game))).to eq(no_label: 1)
      expect(game.reload.name).to eq('Doom (video game)')
    end

    it 'skips labels that are too long to be a name' do
      game = create(:game, name: 'Doom (video game)', wikidata_id: 1)
      stub_labels(1 => 'x' * 121)

      results = []
      service.call(described_class.candidates(Game)) { |result| results << result }

      expect(results.first).to have_attributes(status: :invalid, error: a_string_including('longer than 120'))
      expect(game.reload.name).to eq('Doom (video game)')
    end

    it 'queries the English labels of every record in the batch' do
      create(:game, name: 'Doom (video game)', wikidata_id: 1)
      create(:game, name: 'Quake (video game)', wikidata_id: 2)
      stub_labels({})

      service.call(described_class.candidates(Game))

      expect(WikidataSparql).to have_received(:query).once.with(
        a_string_including('VALUES ?item { wd:Q1 wd:Q2 }').and(including('FILTER(LANG(?label) = "en")'))
      )
    end

    it 'sends one query per batch' do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      Array.new(3) { |i| create(:game, name: "Game #{i} (video game)", wikidata_id: i + 1) }
      stub_labels({})

      service.call(described_class.candidates(Game))

      expect(WikidataSparql).to have_received(:query).twice
    end
  end

  describe WikidataParentheticalNameRefreshService::Result do
    it 'flags names that will still have a parenthetical' do
      expect(described_class.new(old_name: 'Doom (game)', status: :unchanged)).to be_still_parenthetical
      expect(described_class.new(old_name: 'Doom (game)', new_name: 'Doom (video game)', status: :updated)).to be_still_parenthetical
      expect(described_class.new(old_name: 'Doom (game)', new_name: 'Doom', status: :updated)).not_to be_still_parenthetical
    end
  end
end
