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
      "import:update:series"
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
  end

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
end
