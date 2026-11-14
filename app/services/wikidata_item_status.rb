# frozen_string_literal: true

require 'wikidata_sparql'

# Finds which of a set of Wikidata items are no longer usable: items that were
# deleted, and items that were merged into another item (Wikidata turns the
# merged item into a redirect).
#
# Checked in bulk against Wikidata's QLever query service (see WikidataSparql),
# a chunk of items per query:
#
#   * redirected -> the item has an `owl:sameAs` triple pointing at the item it
#     was merged into. Wikidata leaves this on the old Q-ID.
#   * deleted    -> the item isn't a redirect and has neither a statement nor a
#     label left.
#   * fine       -> anything else; not returned.
#
# Redirects are followed to their final target, so a game can be pointed
# straight at it. A redirect whose target has itself been deleted counts as a
# deletion.
#
# This is the same detection as script/find_stale_wikidata_ids.rb, which runs
# without the app against vglist's public API.
class WikidataItemStatus
  # Items per SPARQL round-trip. The statement query returns a row per item
  # and property, and larger chunks have made the endpoint time out (see
  # script/find_stale_wikidata_ids.rb).
  CHUNK_SIZE = 100

  # How many redirects to follow before giving up. Wikidata fixes double
  # redirects, so more than one hop is rare.
  MAX_REDIRECT_HOPS = 3

  # `state` is :deleted or :redirected. `redirect_target` is the Wikidata ID
  # the item now redirects to (after following any further redirects), for
  # :redirected only.
  Status = Struct.new(:wikidata_id, :state, :redirect_target, keyword_init: true)

  # @param [Integer] chunk_size items per SPARQL query
  def initialize(chunk_size: CHUNK_SIZE)
    @chunk_size = chunk_size
  end

  # Check the given items, yielding after each chunk.
  #
  # @param [Array<Integer>] wikidata_ids
  # @param [Proc] on_chunk called with the number of items in each chunk once
  #   it's been checked, e.g. to advance a progress bar.
  # @return [Hash{Integer => Status}] only the deleted and redirected items
  def stale(wikidata_ids, on_chunk: nil)
    statuses = {}

    wikidata_ids.uniq.each_slice(@chunk_size) do |chunk|
      classify(chunk).each { |status| statuses[status.wikidata_id] = status }
      on_chunk&.call(chunk.length)
    end

    resolve_redirects(statuses)
  end

  private

  # @param [Array<Integer>] chunk
  # @return [Array<Status>]
  def classify(chunk)
    targets = fetch_redirect_targets(chunk)
    missing = chunk - targets.keys - fetch_ids_with_statements(chunk)
    # Only items without statements are worth a label lookup, and there are
    # very few of them, so this is usually skipped or tiny.
    deleted = missing.empty? ? [] : missing - fetch_ids_with_labels(missing)

    targets.map { |id, target| Status.new(wikidata_id: id, state: :redirected, redirect_target: target) } +
      deleted.map { |id| Status.new(wikidata_id: id, state: :deleted) }
  end

  # Point every redirect at its final target, or mark it deleted if that
  # target is gone. Targets are checked the same way as the original items.
  #
  # @param [Hash{Integer => Status}] statuses
  # @return [Hash{Integer => Status}]
  def resolve_redirects(statuses)
    MAX_REDIRECT_HOPS.times do
      targets = statuses.values.select { |s| s.state == :redirected }.map(&:redirect_target).uniq
      break if targets.empty?

      target_statuses = {}
      targets.each_slice(@chunk_size) do |chunk|
        classify(chunk).each { |status| target_statuses[status.wikidata_id] = status }
      end
      break if target_statuses.empty?

      statuses.each_value do |status|
        next unless status.state == :redirected

        case target_statuses[status.redirect_target]&.state
        when :deleted
          status.state = :deleted
          status.redirect_target = nil
        when :redirected
          status.redirect_target = target_statuses[status.redirect_target].redirect_target
        end
      end
    end

    statuses
  end

  # Items in the chunk that redirect to another Wikidata item, as
  # { id => target_id }. owl:sameAs can also point outside Wikidata, so only
  # Q-ID targets count.
  #
  # @return [Hash{Integer => Integer}]
  def fetch_redirect_targets(chunk)
    rows = WikidataSparql.query(<<~SPARQL)
      SELECT ?item ?target WHERE {
        VALUES ?item { #{item_values(chunk)} }
        ?item owl:sameAs ?target.
        FILTER(STRSTARTS(STR(?target), "http://www.wikidata.org/entity/Q"))
      }
    SPARQL

    rows.each_with_object({}) do |row, targets|
      id = qid_to_int(row[:item])
      target = qid_to_int(row[:target])
      targets[id] = target if id && target && id != target
    end
  end

  # Items in the chunk with at least one statement. Matches direct claims
  # (wdt:) only rather than every triple, which would also pull every label,
  # description and sitelink and is heavy enough to time out.
  #
  # @return [Array<Integer>]
  def fetch_ids_with_statements(chunk)
    rows = WikidataSparql.query(<<~SPARQL)
      SELECT DISTINCT ?item WHERE {
        VALUES ?item { #{item_values(chunk)} }
        ?item ?claim ?value.
        ?property wikibase:directClaim ?claim.
      }
    SPARQL

    rows.filter_map { |row| qid_to_int(row[:item]) }
  end

  # Items in the chunk with at least one label, in any language. Guards
  # against deleting a game whose item exists but has no statements yet.
  #
  # @return [Array<Integer>]
  def fetch_ids_with_labels(chunk)
    rows = WikidataSparql.query(<<~SPARQL)
      SELECT DISTINCT ?item WHERE {
        VALUES ?item { #{item_values(chunk)} }
        ?item rdfs:label ?label.
      }
    SPARQL

    rows.filter_map { |row| qid_to_int(row[:item]) }
  end

  def item_values(chunk)
    chunk.map { |id| "wd:Q#{id}" }.join(' ')
  end

  # @return [Integer, nil]
  def qid_to_int(uri)
    match = uri.to_s.match(%r{\Ahttp://www\.wikidata\.org/entity/Q(\d+)\z})
    match && match[1].to_i
  end
end
