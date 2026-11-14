# frozen_string_literal: true

require 'wikidata_sparql'

# Finds games whose Wikidata item is no longer an instance of (P31) a video
# game, e.g. because it was re-typed as DLC, an expansion pack, a mod or a
# film. Read-only: this never writes to the games.
#
# "Video game" means the same classes the games import accepts
# (VIDEO_GAME_CLASSES). Instance-of values are fetched in bulk from Wikidata's
# QLever query service (see WikidataSparql), a chunk of games per query.
class WikidataTypeCheck
  # Games per SPARQL round-trip. Each item only has a handful of P31 values,
  # so chunks can be large.
  CHUNK_SIZE = 1000

  # The P31 classes the games import (`import:wikidata:games`) treats as video
  # games: video game (Q7889) and free or open source video game (Q21125433).
  VIDEO_GAME_CLASSES = [7889, 21_125_433].freeze

  # A game whose item isn't an instance of any video game class.
  #
  # `kind` is :not_a_video_game when the item has other P31 values, listed in
  # `instance_of` (as `Q123 (label)`), or :no_instance_of when it has none. An
  # item that was deleted or merged on Wikidata also has none, so run
  # `vglist:wikidata:clean_stale_items` first to keep those out of the report.
  Result = Struct.new(:kind, :game_id, :wikidata_id, :game_name, :owners, :instance_of, keyword_init: true)

  # @param [ActiveRecord::Relation] games the games to check; games without a
  #   Wikidata ID are skipped.
  def initialize(games: Game.all)
    @games = games.where.not(wikidata_id: nil)
  end

  # The number of games that will be checked.
  delegate :count, to: :@games

  # Check every game and yield each one whose item isn't a video game.
  #
  # @param [Proc] on_chunk called with the number of games in each chunk once
  #   it's been checked, e.g. to advance a progress bar.
  # @yieldparam [Result] result
  # @return [void]
  def each_result(on_chunk: nil)
    @games.in_batches(of: CHUNK_SIZE) do |batch|
      games = batch.pluck(:id, :wikidata_id, :name, :game_purchases_count)
      classes = fetch_classes(games.map { |_, wikidata_id, _, _| wikidata_id }.uniq)

      games.each do |id, wikidata_id, name, owners|
        result = check(id, wikidata_id, name, owners, classes.fetch(wikidata_id, {}))
        yield result if result
      end

      on_chunk&.call(games.length)
    end
  end

  private

  # @param [Hash{Integer => String, nil}] classes the item's P31 values and
  #   their labels
  # @return [Result, nil]
  def check(id, wikidata_id, name, owners, classes)
    return nil if classes.keys.intersect?(VIDEO_GAME_CLASSES)

    Result.new(
      kind: classes.empty? ? :no_instance_of : :not_a_video_game,
      game_id: id,
      wikidata_id: wikidata_id,
      game_name: name,
      owners: owners,
      instance_of: classes.sort.map { |class_id, label| label ? "Q#{class_id} (#{label})" : "Q#{class_id}" }.join('; ')
    )
  end

  # Fetch every P31 value of the given items, with each class's English label.
  #
  # @param [Array<Integer>] wikidata_ids
  # @return [Hash{Integer => Hash{Integer => String, nil}}] item ID => { class
  #   ID => label }; items with no P31 are absent.
  def fetch_classes(wikidata_ids)
    classes = Hash.new { |hash, key| hash[key] = {} }

    WikidataSparql.query(classes_query(wikidata_ids)).each do |row|
      item = qid_to_int(row[:item])
      class_id = qid_to_int(row[:class])
      next unless item && class_id

      classes[item][class_id] ||= row[:classLabel]&.to_s
    end

    classes
  end

  def classes_query(wikidata_ids)
    <<~SPARQL
      SELECT ?item ?class ?classLabel WHERE {
        VALUES ?item { #{wikidata_ids.map { |id| "wd:Q#{id}" }.join(' ')} }
        ?item wdt:P31 ?class.
        OPTIONAL { ?class rdfs:label ?classLabel. FILTER(LANG(?classLabel) = "en") }
      }
    SPARQL
  end

  # @return [Integer, nil]
  def qid_to_int(uri)
    match = uri.to_s.match(%r{\Ahttp://www\.wikidata\.org/entity/Q(\d+)\z})
    match && match[1].to_i
  end
end
