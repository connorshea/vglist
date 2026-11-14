# frozen_string_literal: true

require 'rails_helper'

# vglist:wikidata:clean_stale_items (lib/tasks/wikidata_cleanup.rake) updates
# games whose Wikidata item was merged and deletes unowned games whose item was
# deleted.
RSpec.describe 'vglist:wikidata:clean_stale_items', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('vglist:wikidata:clean_stale_items')
    Rake::Task['vglist:wikidata:clean_stale_items'].reenable
  end

  # Runs the task against a fake Wikidata and returns the CSV rows (without the
  # header) as arrays.
  def run_task(env: {}, **items)
    fake = FakeWikidataItems.new(**items)
    allow(WikidataSparql).to receive(:query) { |sparql| fake.query(sparql) }

    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    with_environment(env) { Rake::Task['vglist:wikidata:clean_stale_items'].invoke }
    $stdout.string.lines(chomp: true).drop(1).map { |line| line.split(',', -1) }
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  it 'deletes a game whose item was deleted when nobody owns or favorited it' do
    game = create(:game, name: 'Gone', wikidata_id: 100)
    create(:game, wikidata_id: 101)

    rows = run_task(deleted: [100])

    expect(rows).to eq([['delete', game.id.to_s, 'Gone', '100', '', '', '0', '0', '']])
    expect(Game.exists?(game.id)).to be(false)
  end

  it 'keeps a game whose item was deleted when someone owns it' do
    game = create(:game, wikidata_id: 100)
    create(:game_purchase, game: game)

    rows = run_task(deleted: [100])

    expect(rows.map { |row| row.values_at(0, 6, 7) }).to eq([%w[keep 1 0]])
    expect(Game.exists?(game.id)).to be(true)
  end

  it 'keeps a game whose item was deleted when someone favorited it' do
    game = create(:game, wikidata_id: 100)
    create(:favorite_game, game: game)

    rows = run_task(deleted: [100])

    expect(rows.map { |row| row.values_at(0, 6, 7) }).to eq([%w[keep 0 1]])
    expect(Game.exists?(game.id)).to be(true)
  end

  it 'points a game at the item its item was merged into' do
    game = create(:game, wikidata_id: 100)

    rows = run_task(redirects: { 100 => 200 })

    expect(rows.map { |row| row.values_at(0, 3, 4) }).to eq([%w[update_id 100 200]])
    expect(game.reload.wikidata_id).to eq(200)
  end

  it 'reports a merge into an item another game already uses as a duplicate' do
    game = create(:game, wikidata_id: 100)
    other = create(:game, wikidata_id: 200)

    rows = run_task(redirects: { 100 => 200 })

    expect(rows.map { |row| row.values_at(0, 4, 5) }).to eq([['duplicate', '200', other.id.to_s]])
    expect(game.reload.wikidata_id).to eq(100)
  end

  it 'reports the second of two games merged into the same item as a duplicate' do
    first = create(:game, wikidata_id: 100)
    second = create(:game, wikidata_id: 101)

    rows = run_task(redirects: { 100 => 200, 101 => 200 })

    expect(rows.map { |row| row.values_at(0, 1, 5) }).to eq(
      [['update_id', first.id.to_s, ''], ['duplicate', second.id.to_s, first.id.to_s]]
    )
    expect(first.reload.wikidata_id).to eq(200)
    expect(second.reload.wikidata_id).to eq(101)
  end

  it 'does not point a game at a blocklisted item' do
    game = create(:game, wikidata_id: 100)
    create(:wikidata_blocklist, wikidata_id: 200)

    rows = run_task(redirects: { 100 => 200 })

    expect(rows.map(&:first)).to eq(['blocklisted'])
    expect(game.reload.wikidata_id).to eq(100)
  end

  it 'changes nothing with DRY_RUN' do
    deleted = create(:game, wikidata_id: 100)
    merged = create(:game, wikidata_id: 101)

    rows = run_task(env: { 'DRY_RUN' => '1' }, deleted: [100], redirects: { 101 => 200 })

    expect(rows.map(&:first)).to eq(%w[delete update_id])
    expect(Game.exists?(deleted.id)).to be(true)
    expect(merged.reload.wikidata_id).to eq(101)
  end

  it 'changes nothing when the plan deletes more than MAX_DELETIONS games' do
    games = Array.new(3) { |i| create(:game, wikidata_id: 100 + i) }
    merged = create(:game, wikidata_id: 110)

    expect do
      run_task(env: { 'MAX_DELETIONS' => '2' }, deleted: [100, 101, 102], redirects: { 110 => 200 })
    end.to raise_error(SystemExit)

    expect(Game.where(id: games.map(&:id)).count).to eq(3)
    expect(merged.reload.wikidata_id).to eq(110)
  end

  it 'leaves games without a Wikidata ID alone' do
    game = create(:game, wikidata_id: nil)

    expect(run_task).to eq([])
    expect(Game.exists?(game.id)).to be(true)
  end

  it 'limits the check to MIN_ID..MAX_ID' do
    games = Array.new(3) { |i| create(:game, wikidata_id: 100 + i) }

    rows = run_task(env: { 'MIN_ID' => games[1].id.to_s, 'MAX_ID' => games[1].id.to_s }, deleted: [100, 101, 102])

    expect(rows.map { |row| row[1].to_i }).to eq([games[1].id])
    expect(Game.where(id: games.map(&:id)).pluck(:id)).to contain_exactly(games[0].id, games[2].id)
  end
end
