# frozen_string_literal: true

namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import MobyGames IDs from Wikidata"
  task mobygames: :environment do
    # mobygames_id is an integer column, so coerce the identifier to one.
    import_external_id(query: mobygames_query, column: :mobygames_id, label: 'MobyGames ID') do |row|
      row[:mobygamesId].to_s.to_i
    end
  end

  desc "Import game covers from MobyGames"
  task 'mobygames:covers': :environment do
    # NOTE: API limitations.
    #   API requests are limited to 360 per hour (one every ten seconds).
    #   In addition, requests should be made no more frequently than one per second.

    puts "This task will try to attach covers to any games which have MobyGames IDs and no cover."

    # Get games with MobyGames IDs and no cover. mobygames_id is a bigint, so
    # nil is its only "missing" value — do NOT add "" here: Rails casts the empty
    # string to nil for an integer column but still emits `mobygames_id = NULL`,
    # which is never true, so `where.not` over it matches zero rows regardless of
    # the data.
    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(mobygames_id: nil)

    puts "Found #{games.count} games with a MobyGames ID and no cover."

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    # Keep track of the number of attached covers.
    attached_covers_count = 0
    no_cover_url_count = 0
    no_matching_game_count = 0

    games.each do |game|
      api_url = "https://api.mobygames.com/v1/games?limit=80&title=#{game[:name]}&api_key=#{ENV['MOBYGAMES_API_KEY']}"
      begin
        api_url = URI.parse(api_url)
      rescue URI::InvalidURIError => e
        # No API request happens for these (e.g. a non-ASCII title can't go in a
        # URI), so skip before the rate-limit sleep rather than wasting 10s on a
        # game we're going to discard anyway.
        progress_bar.log "Invalid URL: #{e}."
        progress_bar.increment
        next
      end

      # progress_bar.log "API URL: #{api_url}"

      # Pace against the MobyGames rate limit, but only now that we know this
      # game yields a valid request URL — games skipped above cost no sleep.
      progress_bar.log ""
      progress_bar.log "Sleeping for 10 seconds..."
      sleep(10)

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

      # The cover URL comes out of the MobyGames API response, so it's fetched
      # through RemoteImageFetcher, which refuses non-public addresses. This
      # also catches the case where the cover image doesn't actually exist.
      begin
        cover = RemoteImageFetcher.fetch(cover_url)
      rescue RemoteImageFetcher::Error => e
        progress_bar.log "Error: #{e}"
        progress_bar.increment
        no_cover_url_count += 1
        next
      end

      # Attach the cover and get the filename from the last fragment of the URL.
      # The downloaded tempfile is thrown away as soon as it's been attached,
      # so an import doesn't accumulate one open file per game it processes.
      begin
        game.cover.attach(io: cover.io, filename: cover.filename)
      ensure
        cover.close
      end

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
              wdt:P11688 ?mobygamesId. # Items with a MobyGames ID.
      }
    SPARQL

    return sparql
  end
end
