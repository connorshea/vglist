# frozen_string_literal: true

require 'wikidata_sparql'

# Re-fetches the names of games and series that end in a Wikipedia-style
# disambiguator, e.g. "Doom (2016 video game)" or "Mario (video game series)",
# from their Wikidata item's English label and updates any that differ.
#
# Those names were imported from Wikidata back when the label itself carried
# the disambiguator. Most labels have since been cleaned up on Wikidata, but
# vglist only reads a name when the record is first imported, so ours still
# have it.
#
# Works like WikidataNameRefreshService: labels come from the SPARQL endpoint
# (QLever by default) through WikidataSparql, in chunks bound with a VALUES
# clause.
class WikidataParentheticalNameRefreshService
  # How many records to look up per SPARQL query. Matches
  # WikidataNameRefreshService.
  BATCH_SIZE = 2500

  # The longest a name can be, from the Game and Series validations.
  MAX_NAME_LENGTH = 120

  # A trailing disambiguator: "(game)", "(video game)", "(2004 video game)",
  # "(video game series)", "(game series)", "(series)", "(video game
  # franchise)" and so on. Deliberately narrow, so something like "Sonic the
  # Hedgehog (Game Gear)" isn't touched.
  PARENTHETICAL = /\s*\((?:\d{4} )?(?:video )?(?:game|game series|game franchise|series|franchise)\)\z/i

  # The same pattern for Postgres's `~*` operator.
  PARENTHETICAL_SQL = '\((\d{4} )?(video )?(game|game series|game franchise|series|franchise)\)$'

  # The models this service covers.
  MODELS = [Game, Series].freeze

  # One record's outcome.
  #
  # status is one of:
  #   :updated        - the name differed from the label and was (or, in a dry
  #                     run, would be) changed.
  #   :unchanged      - the name already matches the label.
  #   :no_wikidata_id - the record isn't linked to Wikidata, so it was skipped.
  #   :no_label       - the item is missing (e.g. deleted or merged), or has no
  #                     English label.
  #   :invalid        - the label can't be used as a name (e.g. it's too long),
  #                     or saving the record failed.
  Result = Struct.new(:record, :old_name, :new_name, :status, :error, keyword_init: true) do
    # Whether the name still ends in a disambiguator after this run, which
    # means the Wikidata label has one too.
    def still_parenthetical?
      name = status == :updated ? new_name : old_name
      name.match?(PARENTHETICAL)
    end
  end

  # @param model [Class] Game or Series.
  # @return [ActiveRecord::Relation] Records of that model whose name ends in a
  #   disambiguator, optionally limited to an inclusive range of IDs. Records
  #   without a Wikidata ID are included so they can be reported.
  def self.candidates(model, min_id: nil, max_id: nil)
    scope = model.where("#{model.table_name}.name ~* ?", PARENTHETICAL_SQL)
    scope = scope.where(id: min_id..) if min_id
    scope = scope.where(id: ..max_id) if max_id
    scope
  end

  # @param dry_run [Boolean] Report what would change without saving.
  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  # Checks every record in the scope against Wikidata.
  #
  # @param records [ActiveRecord::Relation<Game, Series>]
  # @yieldparam result [Result] Each record's outcome, as it's processed.
  # @return [Hash{Symbol => Integer}] How many records ended up in each status.
  def call(records)
    counts = Hash.new(0)

    records.in_batches(of: BATCH_SIZE) do |batch|
      batch = batch.to_a
      wikidata_ids = batch.filter_map(&:wikidata_id)
      labels = wikidata_ids.empty? ? {} : fetch_labels(wikidata_ids)

      batch.each do |record|
        result = refresh(record, labels)
        counts[result.status] += 1
        yield result if block_given?
      end
    end

    counts
  end

  private

  def refresh(record, labels)
    old_name = record.name
    return Result.new(record: record, old_name: old_name, status: :no_wikidata_id) if record.wikidata_id.nil?

    label = labels[record.wikidata_id]
    return Result.new(record: record, old_name: old_name, status: :no_label) if label.nil?
    return Result.new(record: record, old_name: old_name, new_name: label, status: :unchanged) if label == old_name

    if label.length > MAX_NAME_LENGTH
      return Result.new(record: record, old_name: old_name, new_name: label, status: :invalid,
                        error: "label is longer than #{MAX_NAME_LENGTH} characters")
    end

    if !@dry_run && !record.update(name: label)
      return Result.new(record: record, old_name: old_name, new_name: label, status: :invalid,
                        error: record.errors.full_messages.to_sentence)
    end

    Result.new(record: record, old_name: old_name, new_name: label, status: :updated)
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
