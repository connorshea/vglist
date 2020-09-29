# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import GOG.com IDs from Wikidata"
  task gog: :environment do
    puts "Importing GOG.com IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(gog_query))

    games = rows.map do |row|
      next unless row.to_h[:gogId].to_s.start_with?('game/')

      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        gog_id: row.to_h[:gogId].to_s.gsub('game/', '')
      }
    end

    # Reject any nil values that are returned.
    games.reject! { |game| game.nil? }
    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with a GOG.com ID."

    gog_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], gog_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding GOG.com ID '#{game[:gog_id]}' to #{game_record.name}." if ENV['DEBUG']

      begin
        Game.find(game_record.id).update!(gog_id: game[:gog_id])
      rescue ActiveRecord::RecordInvalid => e
        name = game[:name]
        name ||= game_record.name
        progress_bar.log "Invalid: #{name.ljust(30)} | #{e}"
        progress_bar.increment
        next
      end

      progress_bar.log "Added GOG.com ID '#{game[:gog_id]}' to #{game[:name]}."

      gog_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_gog_ids = Game.where.not(gog_id: nil)
    puts
    puts "Done. #{games_with_gog_ids.count} games now have GOG.com IDs."
    puts "#{gog_added_count} GOG.com IDs added."
  end

  # SPARQL query for getting all video games with GOG.com IDs on Wikidata.
  def gog_query
    sparql = <<-SPARQL
      SELECT ?item ?gogId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P2725 ?gogId. # Items with a GOG.com ID.
      }
    SPARQL

    return sparql
  end
end
