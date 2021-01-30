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

  desc "Attach covers to games, only applies to games that have an IGDB ID and don't already have a cover."
  task 'igdb:covers': :environment do
    require 'net/https'

    puts "This task will attach covers to any games which have IGDB IDs and no cover."

    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(igdb_id: [nil, ""])

    puts "Found #{games.count} games with an IGDB ID and no cover."

    cover_not_found_or_errored_count = 0
    cover_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each do |game|
      slugs = ['donut-county', 'star-wars-squadrons', 'hades--1', 'pistol-whip', 'mario-kart-8-deluxe', 'bloons-td-6', 'grand-theft-auto-vice-city', 'grand-theft-auto-iii', 'cyberpunk-2077', 'wolfenstein-youngblood', 'playerunknowns-battlegrounds', 'half-life-alyx', 'factorio', 'stardew-valley', 'poly-bridge', 'superhot-mind-control-delete', 'superhot', 'hexcells-infinite', 'hexcells-plus', 'bastion']
      offset = 0
      igdb_body = <<~TXT
        fields id, slug, cover.url;
        where slug = ("#{slugs.join('", "')}") & cover != null & cover.animated = false;
        sort slug asc;
        limit 100;
        offset #{offset};
      TXT

      igdb_response = igdb_request(
        body: igdb_body,
        access_token: twitch_auth['access_token'],
        endpoint: 'games'
      )

      igdb_response.map! do |igdb_game|
        igdb_game['cover']['url'] = "https:#{igdb_game['cover']['url'].gsub('t_thumb', 't_1080p')}"
        igdb_game
      end
      puts JSON.pretty_generate(igdb_response)

      # Catch the error if the IGDB cover image doesn't actually exist.
      begin
        cover_blob = URI.open(cover_url)
      rescue OpenURI::HTTPError, URI::InvalidURIError => e
        progress_bar.log "#{game[:name].ljust(40)} | Error: #{e}"
        progress_bar.increment
        cover_not_found_or_errored_count += 1
        next
      end

      # Copy the image data to a file with ActiveStorage.
      game.cover.attach(io: cover_blob, filename: (cover_blob.base_uri.to_s.split('/')[-1]).to_s)

      # If the cover has any errors, they'll show up on the `Game` record.
      # Check for any errors and print them if they exist.
      if game.errors.any?
        game.errors.full_messages.each do |msg|
          progress_bar.log "#{game[:name].ljust(40)} | Cover could not be added: #{msg}"
        end
        progress_bar.increment
        cover_not_found_or_errored_count += 1
        next
      end

      # If the cover is invalid but somehow wasn't caught in the last step, do
      # the same thing but with a generic message.
      if game.reload.cover.blank?
        progress_bar.log "#{game[:name].ljust(40)} | Cover could not be added."
        progress_bar.increment
        cover_not_found_or_errored_count += 1
        next
      end

      cover_added_count += 1
      progress_bar.increment
      progress_bar.log "#{game[:name].ljust(40)} | Cover added successfully."
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_covers = Game.joins(:cover_attachment)
    puts
    puts "Done. #{games_with_covers.count} games now have covers."
    puts "#{cover_added_count} covers added and #{cover_not_found_or_errored_count} covers not found or failed to upload."
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

  def twitch_auth
    http = Net::HTTP.new('id.twitch.tv', 443)
    http.use_ssl = true

    uri = URI('https://id.twitch.tv/oauth2/token')
    uri.query = URI.encode_www_form(
      {
        client_id: ENV['TWITCH_CLIENT_ID'],
        client_secret: ENV['TWITCH_CLIENT_SECRET'],
        grant_type: 'client_credentials'
      }
    )

    request = Net::HTTP::Post.new(uri)
    JSON.parse(http.request(request).body)
  end

  def igdb_request(body:, access_token:, endpoint: 'games')
    http = Net::HTTP.new('api.igdb.com', 443)
    http.use_ssl = true

    request = Net::HTTP::Post.new(
      URI("https://api.igdb.com/v4/#{endpoint}"),
      {
        'Client-ID' => ENV['TWITCH_CLIENT_ID'],
        'Authorization' => "Bearer #{access_token}"
      }
    )
    request.body = body

    JSON.parse(http.request(request).body)
  end
end
