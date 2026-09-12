# frozen_string_literal: true

require 'rails_helper'

# import:update:series (lib/tasks/import/update.rake) assigns a game its series
# when it doesn't have one yet, from the game -> series pairs on Wikidata.
RSpec.describe 'import:update:series', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:update:series')
    Rake::Task['import:update:series'].reenable
  end

  # The task narrates itself with `puts` and a progress bar; keep that out of
  # the spec output.
  def run_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['import:update:series'].invoke
  ensure
    $stdout = original
  end

  # The task calls WikidataSparql.query(...) and reads `[:item]`/`[:series]` off
  # each row, so plain hashes stand in for the RDF solutions.
  def stub_sparql(rows)
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  def series_row(game_wikidata_id, series_wikidata_id)
    {
      item: "http://www.wikidata.org/entity/Q#{game_wikidata_id}",
      series: "http://www.wikidata.org/entity/Q#{series_wikidata_id}"
    }
  end

  it 'sets the series on a game that has none' do
    game = create(:game, wikidata_id: 100, series_id: nil)
    series = create(:series, wikidata_id: 500)

    stub_sparql([series_row(100, 500)])

    run_task

    expect(game.reload.series).to eq(series)
  end

  it 'leaves a game that already has a series alone' do
    existing_series = create(:series)
    game = create(:game, wikidata_id: 100, series: existing_series)
    create(:series, wikidata_id: 500)

    stub_sparql([series_row(100, 500)])

    run_task

    expect(game.reload.series).to eq(existing_series)
  end

  it 'ignores a series we do not have' do
    game = create(:game, wikidata_id: 100, series_id: nil)

    stub_sparql([series_row(100, 999)])

    run_task

    expect(game.reload.series).to be_nil
  end

  # As with genres, the games and the Wikidata ID -> Series map are preloaded
  # once. The series here aren't in our DB, so no updates fire and only the
  # preload SELECTs run — before the fix this was a Game.find_by per row plus a
  # Series.find_by per game.
  it 'does not fire a query per game (no N+1)' do
    rows = (1..15).map do |i|
      game = create(:game, wikidata_id: 100 + i, series_id: nil)
      series_row(game.wikidata_id, 9999)
    end
    stub_sparql(rows)

    queries = []
    callback = lambda { |_name, _start, _finish, _id, payload|
      queries << payload[:sql] unless payload[:name] == 'SCHEMA' || payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)
    }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { run_task }

    selects = queries.select { |query| query.lstrip.start_with?('SELECT') }
    expect(selects.length).to be <= 8
  end
end
