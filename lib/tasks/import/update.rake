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
      "import:mobygames",
      "import:update:series",
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

      client = SPARQL::Client.new(
        "https://query.wikidata.org/sparql",
        method: :get,
        headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
      )

      rows = []
      rows.concat(client.query(games_with_series_query))

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
        Game.update(
          hash[:game].id,
          { series_id: series.id }
        )

        updated_games_count += 1
      end

      puts "Added #{updated_games_count} series IDs to games."
    end

    desc "Adds game platforms from Wikidata to games."
    task platforms: :environment do
      puts "Adding game platforms from Wikidata to games."

      # Get all games that have Wikidata IDs.
      games = Game.where.not(wikidata_id: nil).pluck(:wikidata_id)

      client = SPARQL::Client.new(
        "https://query.wikidata.org/sparql",
        method: :get,
        headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
      )

      rows = []
      rows.concat(client.query(games_with_platforms_query))

      games_to_update = []
      rows.map do |row|
        row = row.to_h
        game_wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
        next unless games.include?(game_wikidata_id)

        platform_ids = row[:platforms].to_s.split(', ').map { |plat| plat.delete('Q').to_i }
        games_to_update << {
          game: Game.find_by(wikidata_id: game_wikidata_id),
          platforms: platform_ids
        }
      end

      progress_bar = ProgressBar.create(
        total: games_to_update.count,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      updated_games_count = 0
      games_to_update.each do |hash|
        progress_bar.increment

        progress_bar.log 'Adding platforms.' if ENV['DEBUG']

        # Get the Wikidata IDs for the game's platforms.
        wikidata_ids = hash[:game].platforms.map { |platform| platform[:wikidata_id] }

        # Filter platforms down to just the ones not already represented by
        # an associated GamePlatform.
        platforms_to_add = hash[:platforms].difference(wikidata_ids)

        game_was_updated = false

        platforms_to_add.each do |platform_wikidata_id|
          platform = Platform.find_by(wikidata_id: platform_wikidata_id)
          progress_bar.log platform.inspect if ENV['DEBUG']
          # Go to the next iteration if there's no platform record for the
          # given Wikidata ID.
          next if platform.nil?

          progress_bar.log "Adding #{platform.name} to #{hash[:game].name}."

          # Create a GamePlatform.
          GamePlatform.create(
            game_id: hash[:game].id,
            platform_id: platform.id
          )
          game_was_updated = true
        end

        updated_games_count += 1 if game_was_updated
      end

      puts "Added platforms to #{updated_games_count} games."
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
  #
  # The response is an array of objects that look like this:
  # ```ruby
  # {
  #   item: <RDF id='Q123'>,
  #   itemLabel: Civilization V,
  #   platforms: "Q123, Q124, Q125"
  # }
  # ```
  def games_with_platforms_query
    sparql = <<-SPARQL
      SELECT ?item ?itemLabel (group_concat(distinct ?platform;separator=", ") as ?platforms) with {
        SELECT ?item WHERE
        {
          ?item wdt:P31 wd:Q7889 .
        }
      } as %i
      WHERE {
        include %i
        ?item wdt:P400 ?p1.
        bind(strafter(str(?p1), "http://www.wikidata.org/entity/") as ?platform)
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
      } GROUP BY ?item ?itemLabel
    SPARQL

    return sparql
  end
end
