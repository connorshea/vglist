# frozen_string_literal: true

require 'wikidata_sparql'

# Stands in for Wikidata's query service in specs for WikidataItemStatus and
# the tasks built on it. Answers the redirect, statement and label queries
# WikidataItemStatus sends, for the items listed in each query's VALUES.
#
#   fake = FakeWikidataItems.new(redirects: { 1 => 2 }, deleted: [3])
#   allow(WikidataSparql).to receive(:query) { |sparql| fake.query(sparql) }
#
# Every item exists with a statement and a label unless it's a redirect, is
# listed in `deleted`, or is listed in `labels_only` (a label but no
# statements).
class FakeWikidataItems
  ENTITY = 'http://www.wikidata.org/entity/Q'

  attr_reader :queries

  def initialize(redirects: {}, deleted: [], labels_only: [])
    @redirects = redirects
    @deleted = deleted
    @labels_only = labels_only
    @queries = []
  end

  def query(sparql)
    @queries << sparql
    ids = sparql.scan(/wd:Q(\d+)/).flatten.map(&:to_i)

    if sparql.include?('owl:sameAs')
      ids.select { |id| @redirects.key?(id) }.map { |id| { item: "#{ENTITY}#{id}", target: "#{ENTITY}#{@redirects[id]}" } }
    elsif sparql.include?('wikibase:directClaim')
      ids.reject { |id| gone?(id) || @labels_only.include?(id) }.map { |id| { item: "#{ENTITY}#{id}" } }
    elsif sparql.include?('rdfs:label')
      ids.reject { |id| gone?(id) }.map { |id| { item: "#{ENTITY}#{id}" } }
    else
      raise ArgumentError, "Unexpected query: #{sparql}"
    end
  end

  private

  def gone?(id)
    @redirects.key?(id) || @deleted.include?(id)
  end
end
