# frozen_string_literal: true

require 'rails_helper'

# Most behavior is covered through the task in
# spec/tasks/clean_stale_wikidata_items_spec.rb.
RSpec.describe WikidataStaleGameCleanup do
  before(:each) do
    fake = FakeWikidataItems.new(deleted: [100])
    allow(WikidataSparql).to receive(:query) { |sparql| fake.query(sparql) }
  end

  it 'keeps a game planned for deletion that gained an owner since planning' do
    game = create(:game, wikidata_id: 100)
    cleanup = described_class.new
    result = cleanup.plan.sole

    create(:game_purchase, game: game)
    cleanup.apply!(result)

    expect(result.to_h.slice(:action, :owners)).to eq(action: :keep, owners: 1)
    expect(Game.exists?(game.id)).to be(true)
  end

  it 'does not delete a game whose Wikidata ID changed since planning' do
    game = create(:game, wikidata_id: 100)
    cleanup = described_class.new
    result = cleanup.plan.sole

    game.update!(wikidata_id: 300)
    cleanup.apply!(result)

    expect(Game.exists?(game.id)).to be(true)
  end
end
