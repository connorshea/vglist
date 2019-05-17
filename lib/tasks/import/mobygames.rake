namespace 'import' do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import MobyGames IDs from Wikidata"
  task mobygames: :environment do
    puts "Importing MobyGames IDs from Wikidata..."
    client = SPARQL::Client.new("https://query.wikidata.org/sparql", method: :get)

    rows = []
    rows.concat(client.query(mobygames_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        mobygames_id: row.to_h[:mobygamesId]
      }
    end

    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with a MobyGames ID."

    mobygames_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], mobygames_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding MobyGames ID '#{game[:mobygames_id]}' to #{game_record.name}."

      Game.update(game_record.id, { mobygames_id: game[:mobygames_id] })

      mobygames_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_mobygames_ids = Game.where.not(mobygames_id: nil)
    puts
    puts "Done. #{games_with_mobygames_ids.count} games now have MobyGames IDs."
    puts "#{mobygames_added_count} MobyGames IDs added."
  end

  # SPARQL query for getting all video games with MobyGames IDs on Wikidata.
  def mobygames_query
    sparql = <<-SPARQL
      SELECT ?item ?mobygamesId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P1933 ?mobygamesId. # Items with a MobyGames ID.
      }
    SPARQL

    return sparql
  end
end
