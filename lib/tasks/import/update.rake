# frozen_string_literal: true
namespace :import do
  require 'net/http'
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Runs an import to update all data from Wikidata."
  task update: :environment do
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

    import_tasks.each do |task|
      puts "Running 'rake #{task}'."
      Rake::Task[task].invoke
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

      rows = get_rows(games_with_series_query).map(&:to_h)

      games_to_update = []
      rows.each do |row|
        game_wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
        next unless games_with_no_series.include?(game_wikidata_id)

        series_id = row[:series].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
        games_to_update << {
          game: Game.find_by(wikidata_id: game_wikidata_id),
          series_id: series_id
        }
      end

      progress_bar = ProgressBar.create(
        total: games_to_update.count,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      # Set whodunnit to 'system' for any audited changes made by this Rake task.
      PaperTrail.request.whodunnit = 'system'
      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      updated_games_count = 0
      games_to_update.each do |hash|
        progress_bar.increment

        progress_bar.log 'Adding series.' if ENV['DEBUG']

        series = Series.find_by(wikidata_id: hash[:series_id])
        progress_bar.log series.inspect if ENV['DEBUG']
        next if series.nil?

        progress_bar.log "Adding series ID to #{hash[:game].name}."

        # Update the game to include the missing series ID.
        Game.find(hash[:game].id).update!(series_id: series.id)

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

    # Preload every lookup the loop below used to do one row at a time, the same
    # way the games import (wikidata_import_games.rake) does:
    #   * the games themselves, with their existing associations eager-loaded so
    #     reading `game.genres` fires no query, replacing a `Game.find_by` and a
    #     `game.<props>.pluck` per game, and
    #   * a Wikidata ID -> { id, name } map for the property records (Genre,
    #     Company, ...), replacing a `find_by` per prop per game.
    games_by_wikidata_id = Game.where(wikidata_id: props_by_game_wikidata_id.keys)
                               .includes(plural.to_sym)
                               .index_by(&:wikidata_id)

    prop_class = Object.const_get(klass_name.titleize)
    join_class = Object.const_get("Game#{property_name.titleize}")
    join_foreign_key = "#{klass_name}_id".to_sym
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

      game = games_by_wikidata_id[game_wikidata_id]
      next if game.nil?

      # Uses the eager-loaded association, so this fires no query.
      existing_wikidata_ids = game.public_send(plural).map(&:wikidata_id)

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

        progress_bar.log "Adding #{prop[:name]} to #{game.name}."

        # Create a record for a game join model, e.g. GamePlatform.
        # It needs game_id and then an id for the property, e.g. platform_id
        join_class.create(game_id: game.id, join_foreign_key => prop[:id])
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
