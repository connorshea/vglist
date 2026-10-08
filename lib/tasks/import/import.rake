# frozen_string_literal: true

namespace :import do
  require 'net/http'
  require 'wikidata_sparql'
  require 'ruby-progressbar'

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

  # Set a single external identifier (an IGDB ID, a GOG.com ID, ...) on games
  # from a Wikidata SPARQL query. Shared by import:igdb, import:gog, and the
  # other external-ID tasks, which differ only in the query, the column, the
  # label, and how the value is pulled out of a row.
  #
  # The query must return ?item (the game entity) alongside the identifier. The
  # block receives each row as a hash and returns the value to store, or nil to
  # skip the row (e.g. GOG IDs that aren't for a game). Games we don't have, or
  # that already have the identifier set, are left alone.
  #
  # The candidate games are loaded up front in bounded batches and each is
  # updated in place, rather than running a Game lookup per row and re-finding
  # the record before updating it.
  #
  # @param [String] query the SPARQL query returning ?item and the identifier
  # @param [Symbol] column the Game column to set, e.g. :igdb_id
  # @param [String] label a human name for the identifier, e.g. 'IGDB ID'
  # @yieldparam [Hash] row a result row; return the value to store or nil to skip
  # @return [Integer] the number of games updated
  def import_external_id(query:, column:, label:)
    puts "Importing #{label}s from Wikidata..."

    games = WikidataSparql.query(query).filter_map do |row|
      row = row.to_h
      value = yield(row)
      next if value.nil?

      {
        wikidata_id: row[:item].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i,
        value: value
      }
    end
    games.uniq! { |game| game[:wikidata_id] }

    puts "Found #{games.count} games on Wikidata with #{label}s."

    progress_bar = ProgressBar.create(
      total: games.count,
      format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
    )

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'
    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    # Load the games we actually have that still lack this identifier, keyed by
    # Wikidata ID, in bounded batches — one pass instead of a lookup per row.
    candidates = {}
    games.map { |game| game[:wikidata_id] }.each_slice(5_000) do |wikidata_ids|
      Game.where(wikidata_id: wikidata_ids, column => nil).find_each do |game|
        candidates[game.wikidata_id] = game
      end
    end

    updated_count = 0
    games.each do |game|
      progress_bar.increment

      record = candidates[game[:wikidata_id]]
      next if record.nil?

      begin
        record.update!(column => game[:value])
      rescue ActiveRecord::RecordInvalid => e
        progress_bar.log "Invalid: #{record.name.ljust(30)} | #{e}"
        next
      end

      progress_bar.log "Added #{label} '#{game[:value]}' to #{record.name}."
      updated_count += 1
    end

    progress_bar.finish unless progress_bar.finished?

    puts
    puts "Done. #{Game.where.not(column => nil).count} games now have #{label}s."
    puts "#{updated_count} #{label}s added."

    updated_count
  end
end
