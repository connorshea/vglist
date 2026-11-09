# frozen_string_literal: true

require 'wikidata_sparql'

# Compares each game's name with the label of its Wikidata item, so names that
# have drifted from Wikidata can be reviewed by hand. Read-only: this never
# writes to the games.
#
# The label is the item's English (`en`) label, falling back to its
# multilingual (`mul`) label, which Wikidata uses for names that are the same
# in every language and which some items now carry instead of an `en` label.
#
# Labels are fetched in bulk from QLever (see WikidataSparql), a chunk of games
# per query, rather than with one API call per item.
class WikidataNameCheck
  # Games per SPARQL round-trip. Each row is just an item and up to two labels,
  # so chunks can be large, which cuts down on the per-query pacing sleep.
  CHUNK_SIZE = 2500

  # A game whose name differs from its Wikidata label (`kind: :mismatch`), or
  # whose Wikidata item has neither an `en` nor a `mul` label (`kind:
  # :no_label`, e.g. a deleted or redirected item).
  Result = Struct.new(:kind, :game_id, :wikidata_id, :game_name, :wikidata_label, :label_language, keyword_init: true)

  # @param [ActiveRecord::Relation] games the games to check; games without a
  #   Wikidata ID are skipped.
  def initialize(games: Game.all)
    @games = games.where.not(wikidata_id: nil)
  end

  # The number of games that will be checked.
  delegate :count, to: :@games

  # Check every game and yield each one that doesn't match.
  #
  # @param [Proc] on_chunk called with the number of games in each chunk once
  #   it's been checked, e.g. to advance a progress bar.
  # @yieldparam [Result] result
  # @return [void]
  def each_result(on_chunk: nil)
    @games.in_batches(of: CHUNK_SIZE) do |batch|
      games = batch.pluck(:id, :wikidata_id, :name)
      labels = fetch_labels(games.map { |_, wikidata_id, _| wikidata_id }.uniq)

      games.each do |id, wikidata_id, name|
        result = compare(id, wikidata_id, name, labels[wikidata_id])
        yield result if result
      end

      on_chunk&.call(games.length)
    end
  end

  # Whether a game's name matches a Wikidata label. Both are compared after
  # Unicode NFC normalization and trimming, so invisible encoding differences
  # aren't reported, but everything else (case, punctuation) counts.
  #
  # @param [String] name
  # @param [String] label
  # @return [Boolean]
  def self.same_name?(name, label)
    normalize(name) == normalize(label)
  end

  def self.normalize(string)
    string.unicode_normalize(:nfc).strip
  end
  private_class_method :normalize

  private

  # @return [Result, nil]
  def compare(id, wikidata_id, name, label)
    return Result.new(kind: :no_label, game_id: id, wikidata_id: wikidata_id, game_name: name) if label.nil?

    return nil if self.class.same_name?(name, label[:value])

    Result.new(
      kind: :mismatch,
      game_id: id,
      wikidata_id: wikidata_id,
      game_name: name,
      wikidata_label: label[:value],
      label_language: label[:language]
    )
  end

  # Fetch the `en` (or else `mul`) label for each of the given items.
  #
  # @param [Array<Integer>] wikidata_ids
  # @return [Hash{Integer => Hash}] `{ value:, language: }` per Wikidata ID;
  #   items with neither label are absent.
  def fetch_labels(wikidata_ids)
    labels = {}

    WikidataSparql.query(labels_query(wikidata_ids)).each do |row|
      wikidata_id = row[:item].to_s.delete_prefix('http://www.wikidata.org/entity/Q').to_i

      if row[:enLabel].present?
        labels[wikidata_id] = { value: row[:enLabel].to_s, language: 'en' }
      elsif row[:mulLabel].present?
        labels[wikidata_id] = { value: row[:mulLabel].to_s, language: 'mul' }
      end
    end

    labels
  end

  # SPARQL for the `en` and `mul` labels of a chunk of items. Both are
  # OPTIONAL so every item comes back, and the fallback is picked in Ruby.
  def labels_query(wikidata_ids)
    <<~SPARQL
      SELECT ?item ?enLabel ?mulLabel WHERE {
        VALUES ?item { #{wikidata_ids.map { |id| "wd:Q#{id}" }.join(' ')} }
        OPTIONAL { ?item rdfs:label ?enLabel. FILTER(LANG(?enLabel) = "en") }
        OPTIONAL { ?item rdfs:label ?mulLabel. FILTER(LANG(?mulLabel) = "mul") }
      }
    SPARQL
  end
end
