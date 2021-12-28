# typed: ignore
namespace :import do
  require 'net/http'
  require 'sparql/client'
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

      # Get all games with no series that have Wikidata IDs.
      games_with_no_series = Game.where(series_id: nil).where.not(wikidata_id: nil).pluck(:wikidata_id)

      rows = get_rows(games_with_series_query)

      games_to_update = []
      rows.map do |row|
        row = row.to_h
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
      SELECT ?item ?itemLabel ?series WHERE
      {
        ?item wdt:P31 wd:Q7889; # instance of video game
              wdt:P179 ?series. # in a series
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
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
  #   itemLabel: Civilization V,
  #   genres: "Q123, Q124, Q125"
  # }
  # ```
  def games_with_property_query(property, plural)
    sparql = <<-SPARQL
      SELECT ?item ?itemLabel (group_concat(distinct ?prop;separator=", ") as ?#{plural}) with {
        SELECT ?item WHERE
        {
          ?item wdt:P31 wd:Q7889 .
        }
      } as %i
      WHERE {
        include %i
        ?item wdt:#{property} ?p1.
        bind(strafter(str(?p1), "http://www.wikidata.org/entity/") as ?prop)
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
      } GROUP BY ?item ?itemLabel
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

    puts "Adding game #{property_name.pluralize} from Wikidata to games."

    # Get all games that have Wikidata IDs.
    games = Game.where.not(wikidata_id: nil).pluck(:wikidata_id)

    # This has to use send because methods in Rake tasks are private by default.
    rows = get_rows(send("games_with_#{property_name.pluralize}_query"))

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work and
    # to prevent spamming the logs when running the command.
    Rails.logger.level = 2 if Rails.env.production?

    games_to_update = []
    rows.map do |row|
      row = row.to_h
      game_wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
      next unless games.include?(game_wikidata_id)

      prop_ids = row[property_name.pluralize.to_sym].to_s.split(', ').map { |prop| prop.delete('Q').to_i }
      games_to_update << {
        game: Game.find_by(wikidata_id: game_wikidata_id),
        props: prop_ids
      }
    end

    progress_bar = ProgressBar.create(
      total: games_to_update.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    updated_games_count = 0
    games_to_update.each do |hash|
      progress_bar.increment

      progress_bar.log "Adding #{property_name.pluralize}." if ENV['DEBUG']

      # Get the Wikidata IDs for the game's property.
      wikidata_ids = hash[:game].public_send(property_name.pluralize).pluck(:wikidata_id)

      # Filter props down to just the ones not already represented by
      # an associated game join model, e.g. GamePlatform.
      props_to_add = hash[:props].difference(wikidata_ids)

      game_was_updated = false

      props_to_add.each do |prop_wikidata_id|
        prop = Object.const_get(klass_name.titleize).find_by(wikidata_id: prop_wikidata_id)
        progress_bar.log prop.inspect if ENV['DEBUG']
        # Go to the next iteration if there's no record for the
        # given Wikidata ID.
        next if prop.nil?

        progress_bar.log "Adding #{prop.name} to #{hash[:game].name}."

        # Create a record for a game join model, e.g. GamePlatform.
        # It needs game_id and then an id for the property, e.g. platform_id
        game_join_args = { game_id: hash[:game].id }
        game_join_args["#{klass_name}_id".to_sym] = prop.id

        Object.const_get("Game#{property_name.titleize}").create(
          game_join_args
        )
        game_was_updated = true
      end

      updated_games_count += 1 if game_was_updated
    end

    puts "Added #{property_name.pluralize} to #{updated_games_count} games."
  end

  # Get rows from a SPARQL query.
  # @param [String] query
  # @return [Array<Hash>]
  def get_rows(query)
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.7' }
    )

    rows = []
    rows.concat(client.query(query))
  end
end
