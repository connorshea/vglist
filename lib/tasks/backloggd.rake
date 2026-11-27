# frozen_string_literal: true

namespace :vglist do
  namespace :backloggd do
    # Read-only: fetches the first page of a Backloggd user's Played list the
    # way the importer does and reports what came back, without touching any
    # library. Use it to check that Backloggd's bot protection lets the
    # server's requests through:
    #
    #   bundle exec rake "vglist:backloggd:check[username]"
    desc "Check that vglist can read a Backloggd user's games list."
    task :check, [:username] => :environment do |_task, args|
      fetcher = Backloggd::ListFetcher.new(args[:username])
      url = fetcher.list_url('played', 1)
      puts "Fetching #{url}"

      parser = fetcher.fetch_page('played', 1)
      entries = parser.entries

      puts "OK: #{entries.size} games on the first page#{parser.next_page? ? ', with more pages' : ''}."
      entries.first(5).each { |entry| puts "  #{entry.slug} (#{entry.name}, rating #{entry.rating.inspect})" }
      matched = Game.where(igdb_id: entries.map(&:slug)).count
      puts "#{matched} of them match a game on vglist by IGDB ID."
      puts 'No games found. The page markup may have changed; check the parser against a real page.' if entries.empty?
    rescue Backloggd::ListFetcher::BlockedError => e
      abort "BLOCKED: #{e.message} Backloggd's bot protection is stopping the server's requests."
    rescue Backloggd::ListFetcher::Error => e
      abort "FAILED: #{e.message}"
    end
  end
end
