# frozen_string_literal: true

require 'wikidata_sparql'

# Re-fetches game names from their Wikidata item's English label and updates
# any that differ.
#
# Written for issue #3732: a batch of Amiga games (from Hall of Light) was
# added to Wikidata with library-style names like "Turn, The" or "Long Hard
# Day On The Ranch, A" and imported into vglist that way. Many of the labels
# have since been fixed on Wikidata, but vglist only reads a game's name when
# it's first imported, so ours are still mangled.
#
# Labels come from the SPARQL endpoint (QLever by default) through
# WikidataSparql, which already sends our User-Agent, paces requests and backs
# off when the endpoint is busy or rate limiting. Games are looked up in
# chunks bound with a VALUES clause.
class WikidataNameRefreshService
  # How many games to look up per SPARQL query. Each one returns at most one
  # short row per game, so this is sized for the POST body rather than the
  # result set; it matches the games import's release date chunks.
  BATCH_SIZE = 2500

  # The longest a name can be, from Game's validations.
  MAX_NAME_LENGTH = 120

  # A name that still ends with a moved-to-the-end article, e.g. "Turn, The".
  INVERTED_ARTICLE = /, (?:The|A|An)\z/i

  # One game's outcome.
  #
  # status is one of:
  #   :updated   - the name differed from the label and was (or, in a dry run,
  #                would be) changed.
  #   :unchanged - the name already matches the label.
  #   :no_label  - the item is missing (e.g. deleted or merged), or has no
  #                English label.
  #   :invalid   - the label can't be used as a name (e.g. it's too long), or
  #                saving the game failed.
  Result = Struct.new(:game, :old_name, :new_name, :status, :error, keyword_init: true) do
    # Whether the name still looks inverted after this run, which means the
    # Wikidata label itself needs fixing.
    def still_inverted?
      name = status == :updated ? new_name : old_name
      name.match?(INVERTED_ARTICLE)
    end
  end

  # @return [ActiveRecord::Relation<Game>] Games with a Wikidata ID and a
  #   comma in their name, optionally limited to an inclusive range of game
  #   IDs.
  def self.candidates(min_id: nil, max_id: nil)
    scope = Game.where.not(wikidata_id: nil).where("games.name LIKE '%,%'")
    scope = scope.where(id: min_id..) if min_id
    scope = scope.where(id: ..max_id) if max_id
    scope
  end

  # @param dry_run [Boolean] Report what would change without saving.
  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  # Checks every game in the scope against Wikidata.
  #
  # @param games [ActiveRecord::Relation<Game>]
  # @yieldparam result [Result] Each game's outcome, as it's processed.
  # @return [Hash{Symbol => Integer}] How many games ended up in each status.
  def call(games)
    counts = Hash.new(0)

    games.in_batches(of: BATCH_SIZE) do |batch|
      batch = batch.to_a
      labels = fetch_labels(batch.map(&:wikidata_id))

      batch.each do |game|
        result = refresh(game, labels[game.wikidata_id])
        counts[result.status] += 1
        yield result if block_given?
      end
    end

    counts
  end

  private

  def refresh(game, label)
    old_name = game.name
    return Result.new(game: game, old_name: old_name, status: :no_label) if label.nil?
    return Result.new(game: game, old_name: old_name, new_name: label, status: :unchanged) if label == old_name

    if label.length > MAX_NAME_LENGTH
      return Result.new(game: game, old_name: old_name, new_name: label, status: :invalid,
                        error: "label is longer than #{MAX_NAME_LENGTH} characters")
    end

    if !@dry_run && !game.update(name: label)
      return Result.new(game: game, old_name: old_name, new_name: label, status: :invalid,
                        error: game.errors.full_messages.to_sentence)
    end

    Result.new(game: game, old_name: old_name, new_name: label, status: :updated)
  end

  # @param wikidata_ids [Array<Integer>]
  # @return [Hash{Integer => String}] English label by Wikidata ID. Items that
  #   are missing or have no English label are left out.
  def fetch_labels(wikidata_ids)
    WikidataSparql.query(labels_query(wikidata_ids)).each_with_object({}) do |row, labels|
      label = row[:label].to_s.strip
      next if label.blank?

      labels[row[:item].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i] = label
    end
  end

  def labels_query(wikidata_ids)
    <<~SPARQL
      SELECT ?item ?label WHERE {
        VALUES ?item { #{wikidata_ids.map { |id| "wd:Q#{id}" }.join(' ')} }
        ?item rdfs:label ?label.
        FILTER(LANG(?label) = "en")
      }
    SPARQL
  end
end
