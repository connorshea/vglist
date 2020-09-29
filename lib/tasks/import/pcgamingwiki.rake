# typed: ignore
namespace :import do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import PCGamingWiki IDs from Wikidata"
  task pcgamingwiki: :environment do
    puts "Importing PCGamingWiki IDs from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(pcgamingwiki_query))

    games = rows.map do |row|
      {
        wikidata_id: row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', ''),
        pcgamingwiki_id: row.to_h[:pcgamingwikiId]
      }
    end

    games.uniq! { |e| e[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with a PCGamingWiki ID."

    pcgamingwiki_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each_with_index do |game, _index|
      game_record = Game.where(wikidata_id: game[:wikidata_id], pcgamingwiki_id: nil).first

      unless game_record
        progress_bar.increment
        next
      end

      progress_bar.log "Adding PCGamingWiki ID '#{game[:pcgamingwiki_id]}' to #{game_record.name}." if ENV['DEBUG']

      begin
        Game.find(game_record.id).update!(pcgamingwiki_id: game[:pcgamingwiki_id])
      rescue ActiveRecord::RecordInvalid => e
        name = game[:name]
        name ||= game_record.name
        progress_bar.log "Record Invalid | #{name.ljust(15)} | #{e}"
        progress_bar.increment
        next
      end

      progress_bar.log "Added PCGamingWiki ID '#{game[:pcgamingwiki_id]}' to #{game_record.name}."

      pcgamingwiki_added_count += 1
      progress_bar.increment
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_pcgamingwiki_ids = Game.where.not(pcgamingwiki_id: nil)
    puts
    puts "Done. #{games_with_pcgamingwiki_ids.count} games now have PCGamingWiki IDs."
    puts "#{pcgamingwiki_added_count} PCGamingWiki IDs added."
  end

  desc "Attach covers to games, only applies to games that have a PCGamingWiki ID and don't already have a cover."
  task 'pcgamingwiki:covers': :environment do
    puts "This task will attach covers to any games which have PCGamingWiki IDs and no cover."

    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(pcgamingwiki_id: [nil, ""])

    puts "Found #{games.count} games with a PCGamingWiki ID and no cover."

    cover_not_found_or_errored_count = 0
    cover_added_count = 0

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    games.each do |game|
      progress_bar.log ""
      progress_bar.log "Adding cover for #{game[:name]}."
      api_url = "https://www.pcgamingwiki.com/w/api.php?action=askargs&conditions=#{game[:pcgamingwiki_id].gsub('&', '%26')}&printouts=Cover&format=json"

      begin
        api_url = URI.parse(api_url)
      rescue URI::InvalidURIError
        # I can't get this to work with any other method, so I'm using a
        # deprecated method here.
        # rubocop:disable Lint/UriEscapeUnescape
        api_url = URI.parse(URI.escape(api_url))
        # rubocop:enable Lint/UriEscapeUnescape
      end

      req = Net::HTTP::Get.new(api_url)
      req['Cache-Control'] = 'no-cache'

      res = Net::HTTP.start(api_url.hostname, api_url.port, use_ssl: true) do |http|
        http.request(req)
      end

      json = JSON.parse(res.body)

      json = json.dig('query', 'results')
      if json.nil? || json.blank?
        progress_bar.log "Not finding any covers, skipping."
        cover_not_found_or_errored_count += 1
        progress_bar.increment
        next
      end

      # We don't know the key for the game name, so we just use the first key in the hash (generally there's only one key so this should be fine)
      cover_url = json.dig(json.keys.first, 'printouts', 'Cover').first

      if cover_url.nil?
        progress_bar.log "Not finding any covers, skipping."
        cover_not_found_or_errored_count += 1
        progress_bar.increment
        # Exit early if the game has no cover.
        next
      end

      # The cover URL is returned from the API like //pcgamingwiki.com/images/whatever.png,
      # so we need to turn it into a valid URL.
      cover_url = "https:#{cover_url}" unless cover_url.start_with?('https:')

      # Catch the error if the PCGamingWiki cover image doesn't actually exist.
      begin
        cover_blob = URI.open(cover_url)
      rescue OpenURI::HTTPError, URI::InvalidURIError => e
        progress_bar.log "Error: #{e}"
        progress_bar.increment
        cover_not_found_or_errored_count += 1
        next
      end

      # Copy the image data to a file with ActiveStorage.
      game.cover.attach(io: cover_blob, filename: (cover_blob.base_uri.to_s.split('/')[-1]).to_s)

      if game.reload.cover.blank?
        progress_bar.log "Cover could not be added for #{game[:name]}."
        progress_bar.increment
        cover_not_found_or_errored_count += 1
        next
      end

      cover_added_count += 1
      progress_bar.increment
      progress_bar.log "Cover added to #{game[:name]}."
    end

    progress_bar.finish unless progress_bar.finished?

    games_with_covers = Game.joins(:cover_attachment)
    puts
    puts "Done. #{games_with_covers.count} games now have covers."
    puts "#{cover_added_count} covers added and #{cover_not_found_or_errored_count} covers not found or failed to upload."
  end

  # SPARQL query for getting all video games with PCGamingWiki IDs on Wikidata.
  def pcgamingwiki_query
    sparql = <<-SPARQL
      SELECT ?item ?pcgamingwikiId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P6337 ?pcgamingwikiId. # Items with a PCGamingWiki ID.
      }
    SPARQL

    return sparql
  end
end
