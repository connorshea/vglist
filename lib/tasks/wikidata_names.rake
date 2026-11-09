# frozen_string_literal: true

namespace :vglist do
  namespace :wikidata do
    require 'csv'
    require 'ruby-progressbar'

    # Read-only: reports games whose names differ from their Wikidata labels,
    # but never changes them.
    #
    # The report is CSV on stdout, so it can be redirected to a file; progress
    # and the summary go to stderr. Optional MIN_ID / MAX_ID env vars limit the
    # check to a range of game IDs.
    #
    #   bundle exec rake vglist:wikidata:check_game_names > name_mismatches.csv
    desc "Report games whose names differ from their Wikidata label (en, or mul as a fallback). Read-only."
    task check_game_names: :environment do
      games = Game.all
      games = games.where(id: ENV['MIN_ID'].to_i..) if ENV['MIN_ID'].present?
      games = games.where(id: ..ENV['MAX_ID'].to_i) if ENV['MAX_ID'].present?

      check = WikidataNameCheck.new(games: games)

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      progress_bar = ProgressBar.create(
        total: check.count,
        output: $stderr,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      counts = Hash.new(0)
      columns = %i[kind game_id wikidata_id game_name wikidata_label label_language]

      $stdout.puts columns.join(',')
      check.each_result(on_chunk: ->(size) { progress_bar.progress += size }) do |result|
        counts[result.kind] += 1
        $stdout.puts CSV.generate_line(columns.map { |column| result[column] }).chomp
      end
      progress_bar.finish unless progress_bar.finished?

      warn "Checked #{check.count} games with Wikidata IDs."
      warn "#{counts[:mismatch]} names differ from Wikidata."
      warn "#{counts[:no_label]} Wikidata items have no en or mul label."
    end
  end
end
