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
    # NOTE: MobyGames rate limits (https://www.mobygames.com/info/api/):
    #   non-commercial keys allow 720 requests/hour (one every 5s), legacy keys
    #   360/hour (one every 10s), both capped at 1 request/second. We sleep 10s
    #   per request below, which stays within either tier.

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
      # Pace against the MobyGames rate limit (see NOTE above) before each call.
      progress_bar.log ""
      progress_bar.log "Sleeping for 10 seconds..."
      sleep(10)

      # Look the game up directly by its MobyGames ID. /games/{id} is the
      # single-game convenience endpoint (equivalent to /games?id={id}) and
      # returns the game object directly, so there's no title search to run or
      # moby_url to reconcile — we already know the exact ID. The api_key must be
      # URL-encoded: a base64 key can contain +, /, and =.
      key = URI.encode_www_form_component(ENV['MOBYGAMES_API_KEY'].to_s)
      api_url = URI.parse("https://api.mobygames.com/v1/games/#{game[:mobygames_id]}?api_key=#{key}")

      req = Net::HTTP::Get.new(api_url)
      req['Cache-Control'] = 'no-cache'
      res = Net::HTTP.start(api_url.hostname, api_url.port, use_ssl: true) do |http|
        http.request(req)
      end

      # A 404 just means MobyGames has no game with this ID (a stale or bad
      # mobygames_id); skip it rather than aborting the whole run.
      if res.is_a?(Net::HTTPNotFound)
        progress_bar.log "No MobyGames game found for #{game[:name]} (mobygames_id: #{game[:mobygames_id]})."
        progress_bar.increment
        no_matching_game_count += 1
        next
      end

      # Any other error (a 401 from a missing/expired MOBYGAMES_API_KEY, a 429
      # rate limit, ...) is systemic, so surface it instead of masking it as a
      # missing cover. Safe to resume: the task only processes games that still
      # lack a cover, so a re-run continues where this left off.
      raise "MobyGames API request failed: HTTP #{res.code} #{res.message}. Body: #{res.body.to_s[0, 300]}" unless res.is_a?(Net::HTTPSuccess)

      game_data = JSON.parse(res.body)

      # sample_cover, and its image, may be null (see the API's "Null data" note).
      cover_url = game_data.dig('sample_cover', 'image')
      if cover_url.nil?
        progress_bar.log "No cover image found for #{game[:name]}."
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
