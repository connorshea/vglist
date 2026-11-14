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
    # the summary go to stderr.
    #
    # Games are checked and cleaned up in batches of BATCH_SIZE (default 5000)
    # in ID order, and each batch's rows are written as soon as it's done.
    # After every batch, stderr says which MIN_ID to pass to pick up from the
    # next one, so an interrupted run can be resumed instead of restarted.
    # Optional MIN_ID / MAX_ID env vars limit the check to a range of game IDs,
    # and CHUNK_SIZE sets how many Wikidata items go in each query (default
    # WikidataItemStatus::CHUNK_SIZE).
    #
    # As a guard against a bad response from the query service deleting games
    # en masse, the task stops before deleting more than MAX_DELETIONS games in
    # one run (default 50). Batches already done stay done; nothing in the batch
    # that would cross the limit is changed.
    #
    # To keep it running after a console disconnects, detach it and send its
    # output to files:
    #
    #   DRY_RUN=1 setsid nohup bundle exec rake vglist:wikidata:clean_stale_items \
    #     > stale.csv 2> stale.log < /dev/null &
    desc "Update games whose Wikidata item was merged and delete unowned, unfavorited games whose item was deleted. DRY_RUN=1 to preview."
    task clean_stale_items: :environment do
      dry_run = ENV['DRY_RUN'].present?
      max_deletions = ENV.fetch('MAX_DELETIONS', '50').to_i
      batch_size = ENV.fetch('BATCH_SIZE', '5000').to_i

      games = Game.all
      games = games.where(id: ENV['MIN_ID'].to_i..) if ENV['MIN_ID'].present?
      games = games.where(id: ..ENV['MAX_ID'].to_i) if ENV['MAX_ID'].present?

      item_status = WikidataItemStatus.new(chunk_size: ENV.fetch('CHUNK_SIZE', WikidataItemStatus::CHUNK_SIZE).to_i)
      cleanup = WikidataStaleGameCleanup.new(games: games, item_status: item_status)

      # Limit logging in production to allow the progress bar to work.
      Rails.logger.level = 2 if Rails.env.production?

      total = cleanup.count
      progress_bar = ProgressBar.create(
        total: total,
        output: $stderr,
        format: "\e[0;32m%c/%C |%b>%i| %e\e[0m"
      )

      csv_value = lambda do |value|
        string = value.to_s
        string.match?(/[",\r\n]/) ? "\"#{string.gsub('"', '""')}\"" : string
      end

      columns = %i[action game_id game_name wikidata_id new_wikidata_id other_game_id owners favorites error]
      $stdout.puts columns.join(',')
      $stdout.flush

      counts = Hash.new(0)
      stale_count = 0
      deletions = 0
      resume_from = ENV['MIN_ID'].presence

      cleanup.each_batch(batch_size: batch_size, on_chunk: ->(size) { progress_bar.progress += size }) do |results, last_game_id|
        batch_deletions = results.count { |result| result.action == :delete }
        if !dry_run && deletions + batch_deletions > max_deletions
          progress_bar.stop
          resume = resume_from ? " To pick up from this batch, rerun with MIN_ID=#{resume_from}." : ''
          abort "Stopping: this batch would bring deletions to #{deletions + batch_deletions} " \
                "(MAX_DELETIONS is #{max_deletions}). Nothing in this batch was changed.#{resume} " \
                "Check the plan with DRY_RUN=1, then rerun with a higher MAX_DELETIONS if it's right."
        end
        deletions += batch_deletions

        results.each do |result|
          cleanup.apply!(result) unless dry_run
          counts[result.action] += 1
          $stdout.puts columns.map { |column| csv_value.call(result[column]) }.join(',')
        end
        $stdout.flush
        stale_count += results.length

        resume_from = last_game_id + 1
        progress_bar.log "Done through game ID #{last_game_id} (#{stale_count} stale so far). " \
                         "To resume from here, rerun with MIN_ID=#{resume_from}."
      end
      progress_bar.finish unless progress_bar.finished?

      prefix = dry_run ? 'DRY RUN, nothing was changed. Would have: ' : ''
      warn "Checked #{total} games with Wikidata IDs; #{stale_count} have a deleted or merged item."
      warn "#{prefix}#{counts[:update_id]} Wikidata IDs updated to the merge target."
      warn "#{prefix}#{counts[:delete]} games deleted."
      warn "#{counts[:keep]} games kept because they have owners or favorites (item deleted)."
      warn "#{counts[:duplicate]} games are duplicates of another game (merge by hand)."
      warn "#{counts[:blocklisted]} games redirect to a blocklisted item."
      warn "#{counts[:error]} games failed to update." unless dry_run
    end
  end
end
