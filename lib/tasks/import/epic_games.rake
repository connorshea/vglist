# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Epic Games Store IDs from Wikidata"
  task epic_games: :environment do
    puts "Importing Epic Games Store IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(epic_games_store_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        epic_games_store_id: row.to_h[:epicGamesStoreId]
      }
    end

    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with an Epic Games Store ID."

    epic_games_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], epic_games_store_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding Epic Games Store ID '#{game[:epic_games_store_id]}' to #{game_record.name}." if ENV['DEBUG']

      begin
        Game.find(game_record.id).update!(epic_games_store_id: game[:epic_games_store_id])
      rescue ActiveRecord::RecordInvalid => e
        name = game[:name]
        name ||= game_record.name
        progress_bar.log "Record Invalid | #{name.ljust(15)} | #{e}"
        progress_bar.increment
        next
      end

      progress_bar.log "Added Epic Games Store ID '#{game[:epic_games_store_id]}' to #{game[:name]}."

      epic_games_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_epic_games_store_ids = Game.where.not(epic_games_store_id: nil)
    puts
    puts "Done. #{games_with_epic_games_store_ids.count} games now have Epic Games Store IDs."
    puts "#{epic_games_added_count} Epic Games Store IDs added."
  end

  # SPARQL query for getting all video games with Epic Games Store IDs on Wikidata.
  def epic_games_store_query
    sparql = <<-SPARQL
      SELECT ?item ?epicGamesStoreId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P6278 ?epicGamesStoreId. # Items with an Epic Games Store ID.
      }
    SPARQL

    return sparql
  end
end
