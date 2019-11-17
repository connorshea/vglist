namespace 'import' do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Steam App IDs from Wikidata"
  task steam: :environment do
    puts "Importing Steam App IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(steam_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        steam_app_id: row.to_h[:steamAppId]
      }
    end

    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with a Steam App ID."

    steam_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    # Games with no Steam App IDs.
    games_without_steam_ids = Game.left_outer_joins(:steam_app_ids).where(steam_app_ids: { id: nil })

    valid_wikidata_ids = games_without_steam_ids.map { |game| game[:wikidata_id] }
    valid_wikidata_ids.reject! { |wikidata_id| wikidata_id.nil? }

    games_to_modify = games.select { |game| valid_wikidata_ids.include?(game[:wikidata_id].to_i) }

    games_to_modify.each_with_index do |game, _index|
      game_record = Game.find_by(wikidata_id: game[:wikidata_id])

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding Steam App ID '#{game[:steam_app_id]}' to #{game_record.name}."

      begin
        SteamAppId.create!(game_id: game_record.id, app_id: game[:steam_app_id].to_s)
      rescue ActiveRecord::RecordInvalid => e
        puts "Record Invalid (#{game[:name]}): #{e}"
        progress_bar.increment
        next
      end

      steam_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_steam_app_ids = Game.joins(:steam_app_ids)
    puts
    puts "Done. #{games_with_steam_app_ids.count} games now have Steam App IDs."
    puts "#{steam_added_count} Steam App IDs added."
  end

  # SPARQL query for getting all video games with Steam App IDs on Wikidata.
  def steam_query
    sparql = <<-SPARQL
      SELECT ?item ?steamAppId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P1733 ?steamAppId. # Items with a Steam App ID.
      }
    SPARQL

    return sparql
  end
end
