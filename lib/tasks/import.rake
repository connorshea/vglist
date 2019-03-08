namespace 'import:pcgamingwiki' do
  require 'net/http'

  desc "Attach covers to games, only applies to games that have a PCGamingWiki ID and don't already have a cover."
  task covers: :environment do
    puts "This task will attach covers to any games which have PCGamingWiki IDs and no cover."

    games = Game.includes(:cover_attachment)
                .where(active_storage_attachments: { id: nil })
                .where.not(pcgamingwiki_id: [nil, ""])

    puts "Found #{games.count} games with a PCGamingWiki ID and no cover."

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
      puts "Not finding any covers, skipping." if json.nil? || json.blank?
      next if json.nil? || json.blank?

      # We don't know the key for the game name, so we just use the first key in the hash (generally there's only one key so this should be fine)
      cover_url = json.dig(json.keys.first, 'printouts', 'Cover').first

      puts "Not finding any covers, skipping." if cover_url.nil?
      # Exit early if the game has no cover.
      next if cover_url.nil?

      # The cover URL is returned from the API like //pcgamingwiki.com/images/whatever.png,
      # so we need to turn it into a valid URL.
      cover_url = "https:#{cover_url}"

      cover_blob = URI.open(cover_url)

      # Copy the image data to a file with ActiveStorage.
      game.cover.attach(io: cover_blob, filename: (cover_blob.base_uri.to_s.split('/')[-1]).to_s)

      puts "Cover added to #{game[:name]}."
    end

    games_with_covers = Game.joins(:cover_attachment)
    puts
    puts "Done. #{games_with_covers.count} games now have covers."
  end
end
