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
      "import:mobygames"
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
    desc "Updates game series' for games from Wikidata."
    task series: :environment do
      puts "Importing game series' from games on Wikidata."

      # Get all games with no series that have Wikidata IDs.
      games_with_no_series = Game.where(series_id: nil).where.not(wikidata_id: nil).pluck(:wikidata_id)
      puts games_with_no_series.inspect

      client = SPARQL::Client.new(
        "https://query.wikidata.org/sparql",
        method: :get,
        headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
      )

      rows = []
      rows.concat(client.query(games_with_series_query))

      rows.map do |row|
        row = row.to_h
        row[:item]
        series_id = row[:series].to_s
        puts series_id
      end

      progress_bar = ProgressBar.create(
        total: games.count,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      rows.each do |row|
        progress_bar.increment

        puts 'Adding series.' if ENV['DEBUG']

        series = Series.find_by(wikidata_id: game_hash[:series].first)
        puts series.inspect if ENV['DEBUG']
        next if series.nil?

        Game.update(
          game.id,
          { series_id: series.id }
        )
      end
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
