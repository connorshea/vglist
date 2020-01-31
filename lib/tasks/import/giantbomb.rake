# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Giant Bomb IDs from Wikidata"
  task giantbomb: :environment do
    puts "Importing Giant Bomb IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(giantbomb_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        giantbomb_id: row.to_h[:giantbombId]
      }
    end

    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with a Giant Bomb ID."

    giantbomb_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], giantbomb_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding Giant Bomb ID '#{game[:giantbomb_id]}' to #{game_record.name}."

      Game.update(game_record.id, { giantbomb_id: game[:giantbomb_id] })

      giantbomb_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_giantbomb_ids = Game.where.not(giantbomb_id: nil)
    puts
    puts "Done. #{games_with_giantbomb_ids.count} games now have Giant Bomb IDs."
    puts "#{giantbomb_added_count} Giant Bomb IDs added."
  end

  # SPARQL query for getting all video games with Giant Bomb IDs on Wikidata.
  def giantbomb_query
    sparql = <<-SPARQL
      SELECT ?item ?giantbombId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P5247 ?giantbombId. # Items with a Giant Bomb ID.
      }
    SPARQL

    return sparql
  end
end
