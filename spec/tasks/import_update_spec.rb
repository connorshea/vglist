# frozen_string_literal: true

require 'rails_helper'

# import:update:genres (and its platform/engine/developer/publisher siblings) run
# through add_props_to_games in lib/tasks/import/update.rake. It fetches the
# game -> property associations from Wikidata and creates the missing join rows.
RSpec.describe 'import:update:genres', type: :task do
  before(:each) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('import:update:genres')
    Rake::Task['import:update:genres'].reenable
  end

  # The task narrates itself with `puts` and a progress bar; keep that out of
  # the spec output.
  def run_task
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['import:update:genres'].invoke
  ensure
    $stdout = original
  end

  # The task calls WikidataSparql.query(...) then .map(&:to_h) on the result, so
  # plain hashes stand in for the RDF solutions. `item` is the game and the
  # `genres` string is the group_concat of genre entity URIs the real query
  # returns.
  def stub_sparql(rows)
    allow(WikidataSparql).to receive(:query).and_return(rows)
  end

  def game_row(game_wikidata_id, *genre_wikidata_ids)
    {
      item: "http://www.wikidata.org/entity/Q#{game_wikidata_id}",
      genres: genre_wikidata_ids.map { |id| "Q#{id}" }.join(', ')
    }
  end

  it 'attaches genres from Wikidata that are not already associated' do
    game = create(:game, wikidata_id: 100)
    fps = create(:genre, wikidata_id: 10, name: 'FPS')
    rpg = create(:genre, wikidata_id: 20, name: 'RPG')

    stub_sparql([game_row(100, 10, 20)])

    run_task

    expect(game.reload.genres).to contain_exactly(fps, rpg)
  end

  it 'does not duplicate a genre the game already has' do
    game = create(:game, wikidata_id: 100)
    fps = create(:genre, wikidata_id: 10)
    create(:game_genre, game: game, genre: fps)

    stub_sparql([game_row(100, 10)])

    expect { run_task }.not_to change(GameGenre, :count)
    expect(game.reload.genres).to contain_exactly(fps)
  end

  it 'ignores games not in the database and genres we do not have' do
    game = create(:game, wikidata_id: 100)
    fps = create(:genre, wikidata_id: 10)

    stub_sparql([
                  game_row(100, 10, 999), # Q999 genre isn't in our DB
                  game_row(200, 10) # Q200 game isn't in our DB
                ])

    run_task

    expect(game.reload.genres).to contain_exactly(fps)
  end

  # The whole point of the batch-loading rewrite: the lookups (the games, their
  # existing genres, and the Wikidata ID -> Genre map) are preloaded once, so the
  # query count doesn't grow with the number of games. All games here already
  # have the genre, so no inserts fire and only the preload SELECTs run.
  it 'does not fire a query per game (no N+1)' do
    genre = create(:genre, wikidata_id: 10)
    rows = (1..15).map do |i|
      game = create(:game, wikidata_id: 100 + i)
      create(:game_genre, game: game, genre: genre)
      game_row(game.wikidata_id, 10)
    end
    stub_sparql(rows)

    queries = []
    callback = lambda { |_name, _start, _finish, _id, payload|
      queries << payload[:sql] unless payload[:name] == 'SCHEMA' || payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)
    }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { run_task }

    # A handful of preload SELECTs, constant in the number of games. Before the
    # fix this was a Game.find_by, a genres pluck, and (for new genres) a
    # Genre.find_by per game — dozens of queries at this size.
    selects = queries.select { |query| query.lstrip.start_with?('SELECT') }
    expect(selects.length).to be <= 8
  end
end
