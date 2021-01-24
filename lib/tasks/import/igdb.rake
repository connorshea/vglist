# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import IGDB IDs from Wikidata"
  task igdb: :environment do
    puts "Importing IGDB IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.7' }
    )

    rows = []
    rows.concat(client.query(igdb_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        igdb_id: row.to_h[:igdbId].to_s
      }
    end

    # Reject any nil values that are returned.
    games.reject! { |game| game.nil? }
    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with an IGDB ID."

    igdb_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], igdb_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding IGDB ID '#{game[:igdb_id]}' to #{game_record.name}." if ENV['DEBUG']

      begin
        Game.find(game_record.id).update!(igdb_id: game[:igdb_id])
      rescue ActiveRecord::RecordInvalid => e
        progress_bar.log "Invalid: #{game_record.name.ljust(30)} | #{e}"
        progress_bar.increment
        next
      end

      progress_bar.log "Added IGDB ID '#{game[:igdb_id]}' to #{game_record.name}."

      igdb_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_igdb_ids = Game.where.not(igdb_id: nil)
    puts
    puts "Done. #{games_with_igdb_ids.count} games now have IGDB IDs."
    puts "#{igdb_added_count} IGDB IDs added."
  end

  # SPARQL query for getting all video games with IGDB IDs on Wikidata.
  def igdb_query
    <<-SPARQL
      SELECT ?item ?igdbId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P5794 ?igdbId. # Items with an IGDB ID.
      }
    SPARQL
  end
end
