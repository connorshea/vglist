# frozen_string_literal: true

namespace 'vglist:wikidata' do
  # Issue #3732. See WikidataNameRefreshService for the details.
  #
  # Options (environment variables):
  #   DRY_RUN=1    Report what would change without saving anything.
  #   MIN_ID=n     Only check games with an ID of at least n.
  #   MAX_ID=n     Only check games with an ID of at most n.
  #
  # Every rename goes through PaperTrail, so it shows up in the game's history
  # and can be reverted from there.
  desc "Re-fetch names from Wikidata for games with a comma in their name, e.g. 'Turn, The'."
  task refresh_comma_names: :environment do
    dry_run = ENV['DRY_RUN'].present?
    games = WikidataNameRefreshService.candidates(
      min_id: ENV['MIN_ID'].presence&.to_i,
      max_id: ENV['MAX_ID'].presence&.to_i
    )

    total = games.count
    puts "#{dry_run ? '[DRY RUN] ' : ''}Checking #{total} games with a comma in their name against Wikidata..."
    next if total.zero?

    still_inverted = []

    counts = WikidataNameRefreshService.new(dry_run: dry_run).call(games) do |result|
      game = result.game
      case result.status
      when :updated
        puts "#{dry_run ? 'Would rename' : 'Renamed'} game #{game.id} (Q#{game.wikidata_id}): #{result.old_name.inspect} -> #{result.new_name.inspect}"
      when :no_label
        puts "Skipped game #{game.id} (Q#{game.wikidata_id}): the item is missing or has no English label."
      when :invalid
        puts "Skipped game #{game.id} (Q#{game.wikidata_id}): #{result.error}. Label: #{result.new_name.inspect}"
      end

      still_inverted << result if result.status != :no_label && result.still_inverted?
    end

    if still_inverted.any?
      puts
      puts "#{still_inverted.size} games still have an inverted name because their Wikidata label does too:"
      still_inverted.each do |result|
        puts "  game #{result.game.id}: https://www.wikidata.org/wiki/Q#{result.game.wikidata_id} #{(result.new_name || result.old_name).inspect}"
      end
    end

    puts
    puts "#{dry_run ? '[DRY RUN] ' : ''}Done. " \
         "#{dry_run ? 'Would rename' : 'Renamed'}: #{counts[:updated]}, " \
         "unchanged: #{counts[:unchanged]}, " \
         "no English label: #{counts[:no_label]}, " \
         "skipped: #{counts[:invalid]}."
  end
end
