# frozen_string_literal: true

require 'rails_helper'

# The external-ID import tasks (import:igdb, import:gog, import:epic_games, ...)
# all run through the shared import_external_id helper in
# lib/tasks/import/import.rake. They set a single identifier on games from a
# Wikidata SPARQL query, skipping games we don't have or that already have it.
RSpec.describe 'import external ID tasks', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:epic_games')
    %w[import:epic_games import:gog import:mobygames import:steam].each do |task|
      Rake::Task[task].reenable
    end
  end

  def run_task(name)
    original = $stdout
    $stdout = StringIO.new
    Rake::Task[name].invoke
  ensure
    $stdout = original
  end

  # The tasks call WikidataSparql.query(...) and read the item + identifier off
  # each row, so plain hashes stand in for the RDF solutions.
  def stub_sparql(rows)
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  def game_uri(wikidata_id)
    "http://www.wikidata.org/entity/Q#{wikidata_id}"
  end

  describe 'import:epic_games' do
    it 'sets the id on a game we have that lacks it' do
      game = create(:game, wikidata_id: 100, epic_games_store_id: nil)
      stub_sparql([{ item: game_uri(100), epicGamesStoreId: 'fortnite' }])

      run_task('import:epic_games')

      expect(game.reload.epic_games_store_id).to eq('fortnite')
    end

    it 'leaves a game that already has the id alone' do
      game = create(:game, wikidata_id: 100, epic_games_store_id: 'existing')
      stub_sparql([{ item: game_uri(100), epicGamesStoreId: 'new-value' }])

      run_task('import:epic_games')

      expect(game.reload.epic_games_store_id).to eq('existing')
    end

    it 'ignores games we do not have' do
      stub_sparql([{ item: game_uri(200), epicGamesStoreId: 'whatever' }])

      expect { run_task('import:epic_games') }.not_to raise_error
    end

    # The candidate games are preloaded once, so the query count doesn't grow
    # with the number of Wikidata rows. All games here already have the id, so
    # no updates fire and only the preload SELECTs run.
    it 'does not fire a query per row (no N+1)' do
      rows = (1..15).map do |i|
        create(:game, wikidata_id: 100 + i, epic_games_store_id: "already-#{i}")
        { item: game_uri(100 + i), epicGamesStoreId: "wikidata-#{i}" }
      end
      stub_sparql(rows)

      queries = []
      callback = lambda { |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name] == 'SCHEMA' || payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)
      }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { run_task('import:epic_games') }

      selects = queries.select { |query| query.lstrip.start_with?('SELECT') }
      expect(selects.length).to be <= 6
    end
  end

  describe 'import:gog' do
    it "stores only game/ ids, with the game/ prefix stripped" do
      game = create(:game, wikidata_id: 100, gog_id: nil)
      other = create(:game, wikidata_id: 200, gog_id: nil)
      stub_sparql([
                    { item: game_uri(100), gogId: 'game/half_life' },
                    { item: game_uri(200), gogId: 'movie/some_movie' } # not a game -> skipped
                  ])

      run_task('import:gog')

      expect(game.reload.gog_id).to eq('half_life')
      expect(other.reload.gog_id).to be_nil
    end
  end

  describe 'import:mobygames' do
    it 'stores the id as an integer' do
      game = create(:game, wikidata_id: 100, mobygames_id: nil)
      stub_sparql([{ item: game_uri(100), mobygamesId: '12345' }])

      run_task('import:mobygames')

      expect(game.reload.mobygames_id).to eq(12_345)
    end
  end

  describe 'import:steam' do
    it 'creates a SteamAppId for a game we have that has none' do
      game = create(:game, wikidata_id: 100)
      stub_sparql([{ item: game_uri(100), steamAppId: '440' }])

      run_task('import:steam')

      expect(game.reload.steam_app_ids.map(&:app_id)).to contain_exactly(440)
    end

    it 'skips blocklisted Steam App IDs' do
      game = create(:game, wikidata_id: 100)
      create(:steam_blocklist, steam_app_id: 440)
      stub_sparql([{ item: game_uri(100), steamAppId: '440' }])

      run_task('import:steam')

      expect(game.reload.steam_app_ids).to be_empty
    end
  end
end
