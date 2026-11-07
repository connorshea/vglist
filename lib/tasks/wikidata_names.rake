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

  # Strips Wikipedia-style disambiguators like "(video game)" or "(video game
  # series)" from game and series names, by re-fetching the names from
  # Wikidata. See WikidataParentheticalNameRefreshService for the details.
  #
  # Options (environment variables):
  #   DRY_RUN=1    Report what would change without saving anything.
  #   MIN_ID=n     Only check records with an ID of at least n.
  #   MAX_ID=n     Only check records with an ID of at most n.
  #   MODEL=x      Only check one model, "Game" or "Series".
  #
  # Every rename goes through PaperTrail, so it shows up in the record's history
  # and can be reverted from there.
  desc "Re-fetch names from Wikidata for games and series with a parenthetical like '(video game)' in their name."
  task refresh_parenthetical_names: :environment do
    dry_run = ENV['DRY_RUN'].present?
    prefix = dry_run ? '[DRY RUN] ' : ''
    models = WikidataParentheticalNameRefreshService::MODELS
    models = models.select { |model| model.name.casecmp?(ENV['MODEL']) } if ENV['MODEL'].present?
    abort "Unknown MODEL #{ENV['MODEL'].inspect}, expected Game or Series." if models.empty?

    service = WikidataParentheticalNameRefreshService.new(dry_run: dry_run)

    models.each do |model|
      kind = model.model_name.human.downcase
      records = WikidataParentheticalNameRefreshService.candidates(
        model,
        min_id: ENV['MIN_ID'].presence&.to_i,
        max_id: ENV['MAX_ID'].presence&.to_i
      )

      total = records.count
      puts "#{prefix}Checking #{total} #{kind} records with a parenthetical in their name against Wikidata..."
      next if total.zero?

      no_wikidata_id = []
      still_parenthetical = []

      counts = service.call(records) do |result|
        record = result.record
        case result.status
        when :updated
          puts "#{dry_run ? 'Would rename' : 'Renamed'} #{kind} #{record.id} (Q#{record.wikidata_id}): #{result.old_name.inspect} -> #{result.new_name.inspect}"
        when :no_wikidata_id
          no_wikidata_id << result
        when :no_label
          puts "Skipped #{kind} #{record.id} (Q#{record.wikidata_id}): the item is missing or has no English label."
        when :invalid
          puts "Skipped #{kind} #{record.id} (Q#{record.wikidata_id}): #{result.error}. Label: #{result.new_name.inspect}"
        end

        still_parenthetical << result if %i[unchanged updated].include?(result.status) && result.still_parenthetical?
      end

      if no_wikidata_id.any?
        puts
        puts "#{no_wikidata_id.size} #{kind} records were skipped because they have no Wikidata ID:"
        no_wikidata_id.each do |result|
          puts "  #{kind} #{result.record.id}: #{result.old_name.inspect}"
        end
      end

      if still_parenthetical.any?
        puts
        puts "#{still_parenthetical.size} #{kind} records still have a parenthetical because their Wikidata label does too:"
        still_parenthetical.each do |result|
          puts "  #{kind} #{result.record.id}: https://www.wikidata.org/wiki/Q#{result.record.wikidata_id} #{(result.new_name || result.old_name).inspect}"
        end
      end

      puts
      puts "#{prefix}Done with #{kind}. " \
           "#{dry_run ? 'Would rename' : 'Renamed'}: #{counts[:updated]}, " \
           "unchanged: #{counts[:unchanged]}, " \
           "no Wikidata ID: #{counts[:no_wikidata_id]}, " \
           "no English label: #{counts[:no_label]}, " \
           "skipped: #{counts[:invalid]}."
      puts
    end
  end
end
