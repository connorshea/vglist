namespace :import do
  require 'net/http'

  desc "Runs a full import of companies, engines, genres, platforms, series, games, and optionally covers."
  task :full, [:include_covers] => :environment do |_task, args|
    args.with_defaults(include_covers: false)

    puts 'Running a full import...'
    import_tasks = [
      "import:wikidata:companies",
      "import:wikidata:engines",
      "import:wikidata:genres",
      "import:wikidata:platforms",
      "import:wikidata:series",
      "import:wikidata:games"
    ]

    # Only import covers if the :include_covers argument is true.
    import_tasks << "import:pcgamingwiki:covers" if args[:include_covers]

    import_tasks.each do |task|
      puts "Running 'rake #{task}'."
      Rake::Task[task].invoke
      puts
      puts '-------------------------'
      puts
    end

    puts "Import completed!"
    puts "Run 'bundle exec rake rebuild:multisearch:all' to rebuild all the multisearch indices, or nothing will show up in your search results!"
  end

  desc "Attach covers to games, only applies to games that have a PCGamingWiki ID and don't already have a cover."
  task 'pcgamingwiki:covers': :environment do
    puts "This task will attach covers to any games which have PCGamingWiki IDs and no cover."

    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(pcgamingwiki_id: [nil, ""])

    puts "Found #{games.count} games with a PCGamingWiki ID and no cover."

    cover_not_found_count = 0
    cover_added_count = 0

    games.each do |game|
      puts
      puts "Adding cover for #{game[:name]}."
      api_url = "https://pcgamingwiki.com/w/api.php?action=askargs&conditions=#{game[:pcgamingwiki_id].gsub('&', '%26')}&printouts=Cover&format=json"

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
        puts "Not finding any covers, skipping."
        cover_not_found_count += 1
        next
      end

      # We don't know the key for the game name, so we just use the first key in the hash (generally there's only one key so this should be fine)
      cover_url = json.dig(json.keys.first, 'printouts', 'Cover').first

      if cover_url.nil?
        puts "Not finding any covers, skipping."
        cover_not_found_count += 1
        # Exit early if the game has no cover.
        next
      end

      # The cover URL is returned from the API like //pcgamingwiki.com/images/whatever.png,
      # so we need to turn it into a valid URL.
      cover_url = "https:#{cover_url}"

      cover_blob = URI.open(cover_url)

      # Copy the image data to a file with ActiveStorage.
      game.cover.attach(io: cover_blob, filename: (cover_blob.base_uri.to_s.split('/')[-1]).to_s)

      cover_added_count += 1
      puts "Cover added to #{game[:name]}."
    end

    games_with_covers = Game.joins(:cover_attachment)
    puts
    puts "Done. #{games_with_covers.count} games now have covers."
    puts "#{cover_added_count} covers added and #{cover_not_found_count} covers not found."
  end
end
