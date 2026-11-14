# frozen_string_literal: true

namespace :vglist do
  namespace :wikidata do
    require 'ruby-progressbar'

    # Read-only: reports games whose Wikidata item is no longer an instance of
    # a video game (e.g. re-typed as DLC, an expansion pack or a film), but
    # never changes them. See WikidataTypeCheck.
    #
    # The report is CSV on stdout, so it can be redirected to a file; progress
    # and the summary go to stderr. Optional MIN_ID / MAX_ID env vars limit the
    # check to a range of game IDs.
    #
    #   bundle exec rake vglist:wikidata:check_game_types > not_video_games.csv
    desc "Report games whose Wikidata item is no longer an instance of a video game. Read-only."
    task check_game_types: :environment do
      games = Game.all
      games = games.where(id: ENV['MIN_ID'].to_i..) if ENV['MIN_ID'].present?
      games = games.where(id: ..ENV['MAX_ID'].to_i) if ENV['MAX_ID'].present?

      check = WikidataTypeCheck.new(games: games)

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
      columns = %i[kind game_id wikidata_id game_name owners instance_of]

      $stdout.puts columns.join(',')
      check.each_result(on_chunk: ->(size) { progress_bar.progress += size }) do |result|
        counts[result.kind] += 1
        $stdout.puts columns.map { |column| csv_value.call(result[column]) }.join(',')
      end
      progress_bar.finish unless progress_bar.finished?

      warn "Checked #{check.count} games with Wikidata IDs."
      warn "#{counts[:not_a_video_game]} items are no longer an instance of a video game."
      warn "#{counts[:no_instance_of]} items have no instance of (P31) at all, or were deleted or merged."
    end
  end
end
