# frozen_string_literal: true

namespace :vglist do
  namespace :wikidata do
    require 'ruby-progressbar'

    # Finds games whose Wikidata item was deleted or merged on Wikidata, and
    # cleans them up (see WikidataStaleGameCleanup):
    #
    #   * merged into another item -> the game's Wikidata ID is updated to the
    #     item it was merged into, unless another game already has that ID
    #     (reported as a duplicate to merge by hand) or it's blocklisted.
    #   * deleted -> the game is deleted, but only if nobody owns or
    #     favorited it. Otherwise it's reported and kept.
    #
    # Set DRY_RUN=1 to see what would happen without changing anything. The
    # report is CSV on stdout, so it can be redirected to a file; progress and
    # the summary go to stderr. Optional MIN_ID / MAX_ID env vars limit the
    # check to a range of game IDs.
    #
    # As a guard against a bad response from the query service deleting games
    # en masse, the task refuses to delete more than MAX_DELETIONS games
    # (default 50) and changes nothing if the plan would exceed it.
    #
    #   DRY_RUN=1 bundle exec rake vglist:wikidata:clean_stale_items > stale.csv
    desc "Update games whose Wikidata item was merged and delete unowned, unfavorited games whose item was deleted. DRY_RUN=1 to preview."
    task clean_stale_items: :environment do
      dry_run = ENV['DRY_RUN'].present?
      max_deletions = ENV.fetch('MAX_DELETIONS', '50').to_i

      games = Game.all
      games = games.where(id: ENV['MIN_ID'].to_i..) if ENV['MIN_ID'].present?
      games = games.where(id: ..ENV['MAX_ID'].to_i) if ENV['MAX_ID'].present?

      item_status = WikidataItemStatus.new(chunk_size: ENV.fetch('CHUNK_SIZE', WikidataItemStatus::CHUNK_SIZE).to_i)
      cleanup = WikidataStaleGameCleanup.new(games: games, item_status: item_status)

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      progress_bar = ProgressBar.create(
        total: cleanup.count,
        output: $stderr,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )
      results = cleanup.plan(on_chunk: ->(size) { progress_bar.progress += size })
      progress_bar.finish unless progress_bar.finished?

      planned_deletions = results.count { |result| result.action == :delete }
      if !dry_run && planned_deletions > max_deletions
        abort "Refusing to delete #{planned_deletions} games (MAX_DELETIONS is #{max_deletions}). " \
              "Nothing was changed. Check the plan with DRY_RUN=1, then rerun with a higher MAX_DELETIONS if it's right."
      end

      csv_value = lambda do |value|
        string = value.to_s
        string.match?(/[",\r\n]/) ? "\"#{string.gsub('"', '""')}\"" : string
      end

      columns = %i[action game_id game_name wikidata_id new_wikidata_id other_game_id owners favorites error]
      $stdout.puts columns.join(',')

      results.each do |result|
        cleanup.apply!(result) unless dry_run
        $stdout.puts columns.map { |column| csv_value.call(result[column]) }.join(',')
      end

      counts = results.map(&:action).tally
      prefix = dry_run ? 'DRY RUN, nothing was changed. Would have: ' : ''
      warn "Checked #{cleanup.count} games with Wikidata IDs; #{results.length} have a deleted or merged item."
      warn "#{prefix}#{counts.fetch(:update_id, 0)} Wikidata IDs updated to the merge target."
      warn "#{prefix}#{counts.fetch(:delete, 0)} games deleted."
      warn "#{counts.fetch(:keep, 0)} games kept because they have owners or favorites (item deleted)."
      warn "#{counts.fetch(:duplicate, 0)} games are duplicates of another game (merge by hand)."
      warn "#{counts.fetch(:blocklisted, 0)} games redirect to a blocklisted item."
      warn "#{counts.fetch(:error, 0)} games failed to update." unless dry_run
    end
  end
end
