# frozen_string_literal: true

namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import IGDB IDs from Wikidata"
  task igdb: :environment do
    import_external_id(query: igdb_query, column: :igdb_id, label: 'IGDB ID') do |row|
      row[:igdbId].to_s
    end
  end

  desc "Attach covers to games, only applies to games that have an IGDB ID and don't already have a cover."
  task 'igdb:covers': :environment do
    puts "This task will attach covers to any games which have IGDB IDs and no cover."

    # Only each game's ID and IGDB slug, loaded in batches: this runs in the
    # same container as the web server, and loading every game without a cover
    # as a full record took hundreds of MB before any image work started. Each
    # game's record is loaded when a worker gets to it.
    games = []
    Game.left_joins(:cover_attachment)
        .where(active_storage_attachments: { id: nil })
        .where.not(igdb_id: [nil, ""])
        .in_batches(of: 5_000) { |batch| games.concat(batch.pluck(:id, :igdb_id)) }

    puts "Found #{games.count} games with an IGDB ID and no cover."

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    # Each IGDB cover URL, by slug. Only the URL is kept, not the rest of the
    # API response. The first result wins for any duplicated slug.
    cover_urls_by_slug = {}

    puts "Getting game information from IGDB..."

    # Authenticate with Twitch once up front rather than per batch: the app
    # access token is valid for weeks, so re-requesting it for every group of
    # 50 games was one wasted OAuth round-trip per batch.
    access_token = twitch_auth['access_token']

    fetch_progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    games.in_groups_of(50, false) do |game_batch|
      slugs = game_batch.map(&:second)

      # This format is called APIcalypse and is specific to IGDB.
      # API Docs: https://api-docs.igdb.com/#game
      igdb_body = <<~APICALYPSE
        fields id, slug, cover.url;
        where slug = ("#{slugs.join('", "')}") & cover != null & cover.animated = false;
        sort slug asc;
        limit 50;
      APICALYPSE

      igdb_response = igdb_request(
        body: igdb_body,
        access_token: access_token,
        endpoint: 'games'
      )

      igdb_response.map! do |igdb_game|
        cover_url = igdb_game.dig('cover', 'url')
        if cover_url.nil?
          nil
        else
          # Cover URLs returned from the API look like this (usually):
          # "//images.igdb.com/igdb/image/upload/t_thumb/co2lc8.jpg"
          # So we change it to have a protocol and use the 1080p size.
          includes_protocol = cover_url.start_with?('https:')
          igdb_game['cover']['url'] = "#{includes_protocol ? '' : 'https:'}#{cover_url.gsub('t_thumb', 't_1080p')}"
          igdb_game
        end
      end

      igdb_response.compact.each do |igdb_game|
        cover_urls_by_slug[igdb_game['slug']] ||= igdb_game.dig('cover', 'url')
      end

      # Advance by the number of games in this batch (the last group may be
      # smaller than 50).
      fetch_progress_bar.progress += game_batch.size

      # Sleep to prevent the rate limiter from killing us.
      sleep 1
    end

    fetch_progress_bar.finish unless fetch_progress_bar.finished?

    # The fetch pass has told us which games IGDB actually returned a cover for;
    # drop the rest before the download pass. There's nothing to do for a game
    # with no IGDB cover, so keeping it only skews the progress bar's ETA and
    # holds it in memory. Reassigning games to the filtered subset lets the
    # unmatched ones be collected and removes the per-iteration nil check.
    games_found_count = games.count
    games = games.select { |_id, slug| cover_urls_by_slug.key?(slug) }
    # Seed with the games IGDB had no cover for, so the final tally still counts
    # them; download errors add to it below.
    cover_not_found_or_errored_count = games_found_count - games.count
    cover_added_count = 0

    # Downloads, uploads and resizing are nearly all waiting on the network, so
    # several games are worked on at once. Set CONCURRENCY to change how many.
    # Each worker holds a database connection, and the pool defaults to
    # RAILS_MAX_THREADS (sized for Puma), so make sure it's big enough.
    # Capped at 8, IGDB's limit on open requests. Defaults to 2 because this
    # usually runs in the web server's container, and every worker resizing
    # covers competes with it for CPU and memory.
    concurrency = ENV.fetch('CONCURRENCY', 2).to_i.clamp(1, 8)
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    pool_size = concurrency + 1
    ActiveRecord::Base.establish_connection(db_config.merge(pool: pool_size)) if db_config.fetch(:pool, 5).to_i < pool_size

    puts "#{games.count} of #{games_found_count} games have a cover on IGDB; downloading those (#{concurrency} at a time)."

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Stay within IGDB's rate limit of 4 requests a second across every worker:
    # each download waits for its turn, and turns are 0.25s apart.
    throttle_lock = Mutex.new
    next_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    wait_for_turn = lambda do
      delay = throttle_lock.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        turn = [next_request_at, now].max
        next_request_at = turn + 0.25
        turn - now
      end
      sleep delay if delay.positive?
    end

    # Break the save and sizes steps down further, so a slow run shows whether
    # the time goes to validation (the content type spoofing check spawns the
    # `file` command), the database, or R2. Each worker collects its own
    # numbers in a thread-local hash while a step runs.
    add_to_breakdown = lambda do |key, seconds, count_key = nil|
      breakdown = Thread.current[:igdb_cover_breakdown]
      next if breakdown.nil?

      breakdown[key] += seconds
      breakdown[count_key] += 1 if count_key
    end
    breakdown_subscribers = [
      ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
        add_to_breakdown.call(:sql, event.duration / 1000.0, :queries) unless event.payload[:name] == 'SCHEMA'
      end,
      ActiveSupport::Notifications.subscribe('service_upload.active_storage') do |event|
        add_to_breakdown.call(:upload, event.duration / 1000.0)
      end,
      ActiveSupport::Notifications.subscribe('analyze.active_storage_validations') do |event|
        add_to_breakdown.call(:spoof, event.duration / 1000.0)
      end
    ]
    # There's no notification for running a model's validations, so time them
    # by wrapping Game#run_validations! for the rest of this task's process.
    # Queries run by the validations count towards `validate`, not `sql`, so
    # the parts add up to the step's total.
    Game.prepend(Module.new do
      define_method(:run_validations!) do
        breakdown = Thread.current[:igdb_cover_breakdown]
        sql_before = breakdown&.fetch(:sql, 0)
        queries_before = breakdown&.fetch(:queries, 0)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        super()
      ensure
        if breakdown
          breakdown[:validate] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
          breakdown[:sql] = sql_before
          breakdown[:queries] = queries_before
        end
      end
    end)

    # Attach one game's cover and create its variants.
    #
    # Returns [added, messages]: whether the cover was added, and the lines to
    # log for it.
    attach_cover = lambda do |game, cover_url|
      label = game[:name].ljust(40)
      # How long each step took, logged with the result so a slow run shows
      # where the time goes.
      timings = {}
      breakdowns = {}
      timed = lambda do |step, &block|
        Thread.current[:igdb_cover_breakdown] = Hash.new(0)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
      ensure
        timings[step] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        breakdowns[step] = Thread.current[:igdb_cover_breakdown]
        Thread.current[:igdb_cover_breakdown] = nil
      end
      # e.g. "save 7.48s [validate 3.1s (spoof check 2.9s), sql 0.4s/9, upload 0.6s, other 3.38s]"
      timings_text = lambda do
        timings.map do |step, seconds|
          text = "#{step} #{seconds.round(2)}s"
          b = breakdowns[step]
          next text if b.blank?

          parts = []
          parts << "validate #{b[:validate].round(2)}s (spoof check #{b[:spoof].round(2)}s)" if b.key?(:validate)
          parts << "sql #{b[:sql].round(2)}s/#{b[:queries]}" if b.key?(:sql)
          parts << "upload #{b[:upload].round(2)}s" if b.key?(:upload)
          parts << "other #{(seconds - b[:validate] - b[:sql] - b[:upload]).round(2)}s"
          "#{text} [#{parts.join(', ')}]"
        end.join(', ')
      end
      # The cover URL comes out of the IGDB API response, so it's fetched
      # through RemoteImageFetcher, which refuses non-public addresses. This
      # also catches the case where the cover image doesn't actually exist.
      begin
        timed.call(:wait) { wait_for_turn.call }
        cover = timed.call(:download) { RemoteImageFetcher.fetch(cover_url) }
      rescue RemoteImageFetcher::Error => e
        next [false, ["#{label} | Error: #{e}"]]
      end

      # Throw the downloaded tempfile away once we're done with it, so an import
      # doesn't accumulate one open file per game it processes.
      begin
        # Record the dimensions now, from the local file, so ActiveStorage
        # doesn't queue an AnalyzeJob that downloads the cover again to find
        # them. If libvips can't read it, leave it to the validations below.
        metadata = begin
          image = Vips::Image.new_from_file(cover.io.path)
          { analyzed: true, width: image.width, height: image.height }
        rescue Vips::Error
          {}
        end

        # Call the cover file "123_from_igdb.jpg", where 123 is the vglist game ID.
        timed.call(:save) do
          game.cover.attach(
            io: cover.io,
            filename: "#{game.id}_from_igdb.#{cover.extension.presence || 'jpg'}",
            metadata: metadata
          )
        end

        # If the cover has any errors, they'll show up on the `Game` record.
        errors = game.errors.full_messages.map { |msg| "#{label} | Cover could not be added: #{msg}" }
        next [false, errors] if errors.any?

        # If the cover is invalid but somehow wasn't caught in the last step,
        # report it with a generic message.
        next [false, ["#{label} | Cover could not be added."]] if game.reload.cover.blank?

        # Create each size of the cover now, from the file we already have,
        # rather than leaving it to the TransformJobs `preprocessed: true`
        # queues: those run on the async adapter in this process and are
        # dropped if the task exits first. When they do run, they find the
        # variants already exist and do nothing.
        timed.call(:sizes) { VariantBackfillService.new(game.cover, Game::COVER_SIZES.keys).call(original: cover.io) }
      ensure
        cover.close
      end

      [true, ["#{label} | Cover added successfully (#{timings_text.call})."]]
    end

    queue = Queue.new
    games.each { |pair| queue << pair }
    queue.close
    lock = Mutex.new

    workers = Array.new(concurrency) do
      Thread.new do
        # PaperTrail's whodunnit is per thread.
        PaperTrail.request.whodunnit = 'system'

        while (pair = queue.pop)
          game_id, slug = pair
          added, messages = Rails.application.executor.wrap do
            # Loaded now rather than up front (see above). A game deleted since
            # the list was made is skipped.
            game = Game.find_by(id: game_id)
            game.nil? ? [false, ["Game #{game_id} | Skipped: it no longer exists."]] : attach_cover.call(game, cover_urls_by_slug.fetch(slug))
          end

          lock.synchronize do
            messages.each { |msg| progress_bar.log msg }
            if added
              cover_added_count += 1
            else
              cover_not_found_or_errored_count += 1
            end
            progress_bar.increment
          end
        end
      end
    end
    workers.each(&:join)
    breakdown_subscribers.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }

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
