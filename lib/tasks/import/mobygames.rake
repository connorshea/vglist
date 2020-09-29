# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import MobyGames IDs from Wikidata"
  task mobygames: :environment do
    puts "Importing MobyGames IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

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

      progress_bar.log "Adding MobyGames ID '#{game[:mobygames_id]}' to #{game_record.name}." if ENV['DEBUG']

      begin
        Game.find(game_record.id).update!(mobygames_id: game[:mobygames_id])
      rescue ActiveRecord::RecordInvalid => e
        name = game[:name]
        name ||= game_record.name
        progress_bar.log "Record Invalid | #{name.ljust(15)} | #{e}"
        progress_bar.increment
        next
      end

      progress_bar.log "Added MobyGames ID '#{game[:mobygames_id]}' to #{game_record.name}."

      mobygames_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_mobygames_ids = Game.where.not(mobygames_id: nil)
    puts
    puts "Done. #{games_with_mobygames_ids.count} games now have MobyGames IDs."
    puts "#{mobygames_added_count} MobyGames IDs added."
  end

  desc "Import game covers from MobyGames"
  task 'mobygames:covers': :environment do
    # NOTE: API limitations.
    #   API requests are limited to 360 per hour (one every ten seconds).
    #   In addition, requests should be made no more frequently than one per second.

    puts "This task will try to attach covers to any games which have MobyGames IDs and no cover."

    # Get games with MobyGames IDs and no cover.
    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(mobygames_id: [nil, ""])

    puts "Found #{games.count} games with a MobyGames ID and no cover."

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    # Keep track of the number of attached covers.
    attached_covers_count = 0
    no_cover_url_count = 0
    no_matching_game_count = 0

    games.each do |game|
      progress_bar.log ""
      progress_bar.log "Sleeping for 10 seconds..."
      sleep(10)
      api_url = "https://api.mobygames.com/v1/games?limit=80&title=#{game[:name]}&api_key=#{ENV['MOBYGAMES_API_KEY']}"
      begin
        api_url = URI.parse(api_url)
      rescue URI::InvalidURIError => e
        progress_bar.log e
        # I can't get this to work with any other method, so I'm using a
        # deprecated method here.
        # rubocop:disable Lint/UriEscapeUnescape
        api_url = URI.parse(URI.escape(api_url))
        # rubocop:enable Lint/UriEscapeUnescape
      end

      # progress_bar.log "API URL: #{api_url}"

      # Get the JSON response from the MobyGames API.
      req = Net::HTTP::Get.new(api_url)
      req['Cache-Control'] = 'no-cache'
      res = Net::HTTP.start(api_url.hostname, api_url.port, use_ssl: true) do |http|
        http.request(req)
      end
      json = JSON.parse(res.body)

      mobygames_games = json['games']

      # Move on if no games are returned by the search.
      unless mobygames_games&.length&.positive?
        progress_bar.log "No matching games found for #{game[:name]}."
        progress_bar.increment
        no_matching_game_count += 1
        next
      end

      # Find the first game that matches the mobygames_id we're looking for.
      current_game = mobygames_games.find do |mobygames_game|
        progress_bar.log "moby_url: #{mobygames_game['moby_url']}"
        moby_url = mobygames_game['moby_url']
        moby_url.gsub('http://www.mobygames.com/game/', '') == game[:mobygames_id]
      end

      # Skip if we can't find the current game.
      if current_game.nil?
        progress_bar.log "No matching game found for #{game[:name]} (mobygames_id: #{game[:mobygames_id]})."
        progress_bar.increment
        no_matching_game_count += 1
        next
      end

      cover_url = current_game.dig('sample_cover', 'image')

      if cover_url.nil?
        progress_bar.log "No cover image found."
        progress_bar.increment
        no_cover_url_count += 1
        next
      end

      # Catch the error if the MobyGames cover image doesn't actually exist.
      begin
        cover_blob = URI.open(cover_url)
      rescue OpenURI::HTTPError => e
        progress_bar.log "Error: #{e}"
        progress_bar.increment
        no_cover_url_count += 1
        next
      end

      # Attach the cover and get the filename from the last fragment of the URL.
      game.cover.attach(io: cover_blob, filename: (cover_blob.base_uri.to_s.split('/')[-1]).to_s)
      attached_covers_count += 1
      progress_bar.log "Added cover for #{game[:name]}."
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_covers = Game.joins(:cover_attachment)
    puts
    puts "Done. #{games_with_covers.count} games now have covers."
    puts "#{attached_covers_count} covers added."
    puts "#{no_matching_game_count} IDs could find no matching game, #{no_cover_url_count} games had no cover."
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
