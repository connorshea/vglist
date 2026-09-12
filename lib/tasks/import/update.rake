# frozen_string_literal: true

namespace :import do
  require 'net/http'
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  # Deliberately not `=> :environment`: this task only orchestrates, so it stays
  # a tiny process rather than booting Rails and holding it for the whole run.
  # The subtasks it spawns each depend on :environment themselves.
  desc "Runs an import to update all data from Wikidata."
  task :update do # rubocop:disable Rails/RakeEnvironment
    puts 'Running an import to update all existing games in the database...'

    import_tasks = [
      "import:steam",
      "import:pcgamingwiki",
      "import:giantbomb",
      "import:epic_games",
      "import:gog",
      "import:igdb",
      "import:mobygames",
      "import:update:series",
      "import:update:genres",
      "import:update:engines",
      "import:update:developers",
      "import:update:publishers",
      "import:update:platforms"
    ]

    # Run each subtask in its own process instead of Rake::Task#invoke. Every
    # subtask loads a large Wikidata result set and builds big in-memory maps;
    # in-process, MRI never returns that freed heap to the OS, so the whole run
    # would sit at the peak footprint of the hungriest task. A fresh process per
    # task reclaims everything on exit, keeping the run near a single task's
    # footprint. with_original_env strips this process's Bundler setup so the
    # child's `bundle exec` resolves the project Gemfile cleanly; chdir anchors
    # it to the project root and RAILS_ENV is carried across explicitly.
    rails_root = File.expand_path('../../..', __dir__)
    child_env = { 'RAILS_ENV' => ENV['RAILS_ENV'] }.compact

    import_tasks.each do |task|
      puts "Running 'rake #{task}'."

      run_child = lambda do
        system(child_env, 'bundle', 'exec', 'rake', task, chdir: rails_root)
      end
      succeeded = defined?(Bundler) ? Bundler.with_original_env(&run_child) : run_child.call
      abort("Aborting import:update: 'rake #{task}' failed.") unless succeeded

      puts
      puts '-------------------------'
      puts
    end

    puts "Import completed!"
  end

  namespace :update do
    desc "Adds game series' from Wikidata to games."
    task series: :environment do
      puts "Adding game series' from Wikidata to games."

      # Get all games with no series that have Wikidata IDs. A set, because
      # this is membership-tested once per Wikidata row below.
      games_with_no_series = Game.where(series_id: nil).where.not(wikidata_id: nil).pluck(:wikidata_id).to_set

      # The query returns every video game on Wikidata with a series (~140k
      # rows), so iterate the RDF solutions directly and use delete_prefix
      # rather than allocating a hash and gsubbing per row.
      rows = get_rows(games_with_series_query)

      # Series Wikidata ID to set, keyed by the game's Wikidata ID so the games
      # can be batch-loaded below. The query isn't grouped by ?item, so a game
      # with more than one series yields more than one row; the last wins, as
      # the previous row-by-row version also did.
      series_by_game_wikidata_id = {}
      rows.each do |row|
        game_wikidata_id = row[:item].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i
        next unless games_with_no_series.include?(game_wikidata_id)

        series_by_game_wikidata_id[game_wikidata_id] =
          row[:series].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i
      end

      # The ~140k rows and the games_with_no_series set have been reduced into
      # series_by_game_wikidata_id and aren't read again; drop them so they can
      # be garbage-collected before the loop below rather than held alongside it.
      # rubocop:disable Lint/UselessAssignment
      rows = nil
      games_with_no_series = nil
      # rubocop:enable Lint/UselessAssignment

      # Preload the games and a Wikidata ID -> Series ID map once, instead of a
      # Game.find_by per row and a Series.find_by per game.
      games_by_wikidata_id = Game.where(wikidata_id: series_by_game_wikidata_id.keys).index_by(&:wikidata_id)
      series_id_by_wikidata_id = Series.where.not(wikidata_id: nil).pluck(:wikidata_id, :id).to_h

      progress_bar = ProgressBar.create(
        total: series_by_game_wikidata_id.count,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      # Set whodunnit to 'system' for any audited changes made by this Rake task.
      PaperTrail.request.whodunnit = 'system'
      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      updated_games_count = 0
      series_by_game_wikidata_id.each do |game_wikidata_id, series_wikidata_id|
        progress_bar.increment

        progress_bar.log 'Adding series.' if ENV['DEBUG']

        game = games_by_wikidata_id[game_wikidata_id]
        next if game.nil?

        series_id = series_id_by_wikidata_id[series_wikidata_id]
        next if series_id.nil?

        progress_bar.log "Adding series ID to #{game.name}."

        # Update the game to include the missing series ID.
        game.update!(series_id: series_id)

        updated_games_count += 1
      end

      puts "Added #{updated_games_count} series IDs to games."
    end

    desc "Adds game platforms from Wikidata to games."
    task platforms: :environment do
      add_props_to_games('platform')
    end

    desc "Adds game genres from Wikidata to games."
    task genres: :environment do
      add_props_to_games('genre')
    end

    desc "Adds game engines from Wikidata to games."
    task engines: :environment do
      add_props_to_games('engine')
    end

    desc "Adds game developers from Wikidata to games."
    task developers: :environment do
      add_props_to_games('developer', 'company')
    end

    desc "Adds game publishers from Wikidata to games."
    task publishers: :environment do
      add_props_to_games('publisher', 'company')
    end
  end

  # Games with an associated series.
  def games_with_series_query
    sparql = <<-SPARQL
      SELECT ?item ?series WHERE
      {
        ?item wdt:P31 wd:Q7889; # instance of video game
              wdt:P179 ?series. # in a series
      }
    SPARQL

    return sparql
  end

  # Returns games with at least one platform.
  def games_with_platforms_query
    return games_with_property_query('P400', 'platforms')
  end

  # Returns games with at least one genre.
  def games_with_genres_query
    return games_with_property_query('P136', 'genres')
  end

  # Returns games with at least one engine.
  def games_with_engines_query
    return games_with_property_query('P408', 'engines')
  end

  # Returns games with at least one developer.
  def games_with_developers_query
    return games_with_property_query('P178', 'developers')
  end

  # Returns games with at least one publisher.
  def games_with_publishers_query
    return games_with_property_query('P123', 'publishers')
  end

  # Returns a SPARQL query for a given property.
  #
  # @param [String] property Property ID, like 'P123'.
  # @params [String] plural Plural name of the variable, e.g. 'genres'.
  # @return [String]
  #
  # Returns games with at least one of this property.
  #
  # The response from the query is an array of objects that look like this:
  # ```ruby
  # {
  #   item: <RDF id='Q123'>,
  #   genres: "Q123, Q124, Q125"
  # }
  # ```
  def games_with_property_query(property, plural)
    sparql = <<-SPARQL
      SELECT ?item (group_concat(distinct ?prop;separator=", ") as ?#{plural}) WHERE {
        ?item wdt:P31 wd:Q7889; # instance of video game
              wdt:#{property} ?p1.
        bind(strafter(str(?p1), "http://www.wikidata.org/entity/") as ?prop)
      } GROUP BY ?item
    SPARQL

    return sparql
  end

  # A metaprogrammed abomination for creating records associated with games,
  # e.g. GamePlatforms.
  #
  # @param [String] property_name The singular name of the property, e.g. 'platform'.
  # @param [String] klass_name The singular name of the corresponding class
  #    if it differs from the titleized property name, e.g. 'company'.
  # @return [void]
  def add_props_to_games(property_name, klass_name = nil)
    klass_name = property_name if klass_name.nil?
    plural = property_name.pluralize

    puts "Adding game #{plural} from Wikidata to games."

    # Get all games that have Wikidata IDs. A set, because this is
    # membership-tested once per Wikidata row below.
    games = Game.where.not(wikidata_id: nil).pluck(:wikidata_id).to_set

    # This has to use send because methods in Rake tasks are private by default.
    # Iterate the RDF solutions directly (they support `[:item]`) rather than
    # mapping them all to hashes first — the query returns every video game on
    # Wikidata with this property (~140k rows), so that intermediate array is
    # pure allocation we filter away below.
    rows = get_rows(send("games_with_#{plural}_query"))

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work and
    # to prevent spamming the logs when running the command.
    Rails.logger.level = 2 if Rails.env.production?

    # Collect the prop Wikidata IDs each game should gain, keyed by the game's
    # Wikidata ID so we can batch-load the games below. The query groups by
    # ?item, so there's one row per game and no risk of clobbering.
    props_by_game_wikidata_id = {}
    rows.each do |row|
      game_wikidata_id = row[:item].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i
      next unless games.include?(game_wikidata_id)

      props_by_game_wikidata_id[game_wikidata_id] =
        row[plural.to_sym].to_s.split(', ').map { |prop| prop.delete('Q').to_i }
    end

    prop_class = Object.const_get(klass_name.titleize)
    join_class = Object.const_get("Game#{property_name.titleize}")
    join_foreign_key = "#{klass_name}_id".to_sym

    # The rows have been reduced into props_by_game_wikidata_id above and are
    # never read again; drop the reference so the ~140k heavyweight RDF solutions
    # can be garbage-collected before we build the maps below, instead of being
    # held in memory alongside them.
    rows = nil # rubocop:disable Lint/UselessAssignment

    # Preload every lookup the loop below used to do one row at a time, but
    # without instantiating a single Game or Genre/Company record — on a full
    # update that eager-loaded AR object graph is where the memory went. We only
    # need each game's id (to build the join rows) and name (to log), plus the
    # Wikidata IDs of the props it already has:
    #   * a Wikidata ID -> { id, name } map for the candidate games,
    #   * the Wikidata IDs of the props each game already has, pulled straight
    #     from the join without instantiating the associations (games with none
    #     simply don't appear), and
    #   * a Wikidata ID -> { id, name } map for the property records (Genre,
    #     Company, ...), replacing a `find_by` per prop per game.
    game_wikidata_ids = props_by_game_wikidata_id.keys
    game_info_by_wikidata_id = Game.where(wikidata_id: game_wikidata_ids)
                                   .pluck(:wikidata_id, :id, :name)
                                   .to_h { |wikidata_id, id, name| [wikidata_id, { id: id, name: name }] }

    existing_prop_wikidata_ids_by_game = {}
    Game.where(wikidata_id: game_wikidata_ids)
        .joins(plural.to_sym)
        .pluck('games.wikidata_id', "#{prop_class.table_name}.wikidata_id")
        .each do |game_wikidata_id, prop_wikidata_id|
          (existing_prop_wikidata_ids_by_game[game_wikidata_id] ||= []) << prop_wikidata_id
        end

    prop_by_wikidata_id = prop_class.where.not(wikidata_id: nil)
                                    .pluck(:wikidata_id, :id, :name)
                                    .to_h { |wikidata_id, id, name| [wikidata_id, { id: id, name: name }] }

    progress_bar = ProgressBar.create(
      total: props_by_game_wikidata_id.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    updated_games_count = 0
    props_by_game_wikidata_id.each do |game_wikidata_id, prop_wikidata_ids|
      progress_bar.increment

      progress_bar.log "Adding #{plural}." if ENV['DEBUG']

      game = game_info_by_wikidata_id[game_wikidata_id]
      next if game.nil?

      # Pulled from the join above, so this fires no query.
      existing_wikidata_ids = existing_prop_wikidata_ids_by_game[game_wikidata_id] || []

      # Filter props down to just the ones not already represented by
      # an associated game join model, e.g. GamePlatform.
      props_to_add = prop_wikidata_ids.difference(existing_wikidata_ids)

      game_was_updated = false

      props_to_add.each do |prop_wikidata_id|
        prop = prop_by_wikidata_id[prop_wikidata_id]
        progress_bar.log prop.inspect if ENV['DEBUG']
        # Go to the next iteration if there's no record for the
        # given Wikidata ID.
        next if prop.nil?

        progress_bar.log "Adding #{prop[:name]} to #{game[:name]}."

        # Create a record for a game join model, e.g. GamePlatform.
        # It needs game_id and then an id for the property, e.g. platform_id
        join_class.create(game_id: game[:id], join_foreign_key => prop[:id])
        game_was_updated = true
      end

      updated_games_count += 1 if game_was_updated
    end

    puts "Added #{plural} to #{updated_games_count} games."
  end

  # Get rows from a SPARQL query.
  # @param [String] query
  # @return [Array<Hash>]
  def get_rows(query)
    WikidataSparql.query(query)
  end
end
