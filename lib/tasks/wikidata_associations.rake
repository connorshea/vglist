# frozen_string_literal: true

namespace :vglist do
  namespace :wikidata do
    require 'ruby-progressbar'

    # Read-only: reports platforms, genres, engines, developers, publishers and
    # series on games that the game's Wikidata item doesn't have, but never
    # removes them. See WikidataAssociationCheck.
    #
    # The report is CSV on stdout, so it can be redirected to a file; progress
    # and the summary go to stderr. Optional env vars:
    #
    #   ASSOCIATIONS   comma-separated subset to check, e.g. platforms,genres
    #                  (default: all of them)
    #   INCLUDE_EMPTY  also report associations for properties the Wikidata
    #                  item has no values for at all (noisier)
    #   MIN_ID/MAX_ID  limit the check to a range of game IDs
    #
    #   bundle exec rake vglist:wikidata:check_game_associations > associations.csv
    desc "Report game platforms, genres, engines, developers, publishers and series that Wikidata doesn't have. Read-only."
    task check_game_associations: :environment do
      games = Game.all
      games = games.where(id: ENV['MIN_ID'].to_i..) if ENV['MIN_ID'].present?
      games = games.where(id: ..ENV['MAX_ID'].to_i) if ENV['MAX_ID'].present?

      associations = ENV['ASSOCIATIONS'].presence&.split(',')&.map { |name| name.strip.to_sym } ||
                     WikidataAssociationCheck::ASSOCIATIONS.keys

      check = WikidataAssociationCheck.new(
        games: games,
        associations: associations,
        include_empty: ENV['INCLUDE_EMPTY'].present?
      )

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      progress_bar = ProgressBar.create(
        total: check.count,
        output: $stderr,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      csv_value = lambda do |value|
        string = value.to_s
        string.match?(/[",\r\n]/) ? "\"#{string.gsub('"', '""')}\"" : string
      end

      counts = Hash.new(0)
      columns = %i[association game_id game_name game_wikidata_id record_id record_name record_wikidata_id wikidata_values]

      $stdout.puts columns.join(',')
      check.each_result(on_chunk: ->(size) { progress_bar.progress += size }) do |result|
        counts[result.association] += 1
        $stdout.puts columns.map { |column| csv_value.call(result[column]) }.join(',')
      end
      progress_bar.finish unless progress_bar.finished?

      warn "Checked #{check.count} games with Wikidata IDs."
      associations.each do |association|
        warn "#{counts[association]} #{association} not on Wikidata."
      end
    end
  end
end
