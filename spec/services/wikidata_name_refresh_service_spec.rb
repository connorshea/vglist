# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikidataNameRefreshService, type: :service do
  # The service reads `[:item]`/`[:label]` off each row, so plain hashes stand
  # in for the RDF solutions WikidataSparql.query returns.
  def stub_labels(labels)
    rows = labels.map { |id, label| { item: "http://www.wikidata.org/entity/Q#{id}", label: label } }
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  def service(dry_run: false)
    described_class.new(dry_run: dry_run)
  end

  describe '.candidates' do
    it 'finds games with a comma in their name and a Wikidata ID' do
      inverted = create(:game, name: 'Turn, The', wikidata_id: 1)
      create(:game, name: 'The Turn', wikidata_id: 2)
      create(:game, name: 'Ranch, A', wikidata_id: nil)

      expect(described_class.candidates).to contain_exactly(inverted)
    end

    it 'limits to a range of game IDs' do
      games = Array.new(3) { |i| create(:game, name: "Game #{i}, The", wikidata_id: i + 1) }

      expect(described_class.candidates(min_id: games[1].id, max_id: games[1].id)).to contain_exactly(games[1])
      expect(described_class.candidates(min_id: games[1].id)).to contain_exactly(games[1], games[2])
      expect(described_class.candidates(max_id: games[1].id)).to contain_exactly(games[0], games[1])
    end
  end

  describe '#call' do
    it 'updates names that differ from the English label' do
      game = create(:game, name: 'Turn, The', wikidata_id: 126_187_255)
      stub_labels(126_187_255 => 'The Turn')

      results = []
      counts = service.call(described_class.candidates) { |result| results << result }

      expect(game.reload.name).to eq('The Turn')
      expect(counts).to eq(updated: 1)
      expect(results.first).to have_attributes(old_name: 'Turn, The', new_name: 'The Turn', status: :updated)
    end

    it 'records the rename in the version history', versioning: true do
      game = create(:game, name: 'Turn, The', wikidata_id: 1)
      stub_labels(1 => 'The Turn')

      expect { service.call(described_class.candidates) }.to change { game.versions.count }.by(1)
    end

    it 'leaves names that already match alone' do
      game = create(:game, name: 'Hello, World', wikidata_id: 1)
      stub_labels(1 => 'Hello, World')

      expect(service.call(described_class.candidates)).to eq(unchanged: 1)
      expect(game.reload.name).to eq('Hello, World')
    end

    it 'does not save anything in a dry run' do
      game = create(:game, name: 'Turn, The', wikidata_id: 1)
      stub_labels(1 => 'The Turn')

      expect(service(dry_run: true).call(described_class.candidates)).to eq(updated: 1)
      expect(game.reload.name).to eq('Turn, The')
    end

    it 'skips items with no English label' do
      game = create(:game, name: 'Turn, The', wikidata_id: 1)
      stub_labels({})

      expect(service.call(described_class.candidates)).to eq(no_label: 1)
      expect(game.reload.name).to eq('Turn, The')
    end

    it 'skips labels that are too long to be a name' do
      game = create(:game, name: 'Turn, The', wikidata_id: 1)
      stub_labels(1 => 'x' * 121)

      results = []
      service.call(described_class.candidates) { |result| results << result }

      expect(results.first).to have_attributes(status: :invalid, error: a_string_including('longer than 120'))
      expect(game.reload.name).to eq('Turn, The')
    end

    it 'queries the English labels of every game in the batch' do
      create(:game, name: 'Turn, The', wikidata_id: 1)
      create(:game, name: 'Ranch, A', wikidata_id: 2)
      stub_labels({})

      service.call(described_class.candidates)

      expect(WikidataSparql).to have_received(:query).once.with(
        a_string_including('VALUES ?item { wd:Q1 wd:Q2 }').and(including('FILTER(LANG(?label) = "en")'))
      )
    end

    it 'sends one query per batch' do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      Array.new(3) { |i| create(:game, name: "Game #{i}, The", wikidata_id: i + 1) }
      stub_labels({})

      service.call(described_class.candidates)

      expect(WikidataSparql).to have_received(:query).twice
    end
  end

  describe WikidataNameRefreshService::Result do
    it 'flags names that will still be inverted' do
      expect(described_class.new(old_name: 'Turn, The', status: :unchanged)).to be_still_inverted
      expect(described_class.new(old_name: 'Turn, The', new_name: 'Ranch, A', status: :updated)).to be_still_inverted
      expect(described_class.new(old_name: 'Turn, The', new_name: 'The Turn', status: :updated)).not_to be_still_inverted
    end
  end
end
