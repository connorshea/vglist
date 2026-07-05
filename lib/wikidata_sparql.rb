# frozen_string_literal: true

require 'sparql/client'

# Shared configuration for querying Wikidata over SPARQL.
#
# We query QLever's hosted Wikidata mirror
# (https://qlever.dev/wikidata) rather than the official Wikidata Query
# Service (WDQS). QLever is dramatically faster and has no query timeout, at the
# cost of lagging real Wikidata by up to ~1 week — fine for our import tasks.
#
# Two things differ from WDQS, and the queries in lib/tasks/import are written
# with them in mind:
#
#   * QLever does not implicitly define the standard Wikidata prefixes, so every
#     query is prefixed with PREFIXES below (WDQS injects these for you).
#   * QLever doesn't support Blazegraph-specific extensions, so queries avoid the
#     `wikibase:label` service and `with { ... } as %name` named subqueries.
module WikidataSparql
  # The SPARQL endpoint to query. Override with the WIKIDATA_SPARQL_ENDPOINT env
  # var to fall back to WDQS ("https://query.wikidata.org/sparql") without a
  # deploy if QLever is ever lagging or unavailable.
  ENDPOINT = ENV.fetch('WIKIDATA_SPARQL_ENDPOINT', 'https://qlever.dev/api/wikidata')

  # Contact email advertised in the User-Agent per Wikimedia's user-agent
  # policy. Optional and unset by default — set WIKIDATA_CONTACT_EMAIL to
  # include a contact address (recommended when running imports in production).
  USER_AGENT = [
    'vglist Data Fetcher/1.0',
    ENV['WIKIDATA_CONTACT_EMAIL'].present? ? "(#{ENV['WIKIDATA_CONTACT_EMAIL']})" : nil,
    'Ruby 3.0'
  ].compact.join(' ')

  # Standard Wikidata prefixes. WDQS provides these implicitly; QLever requires
  # them to be declared explicitly on every query.
  PREFIXES = <<~SPARQL
    PREFIX wd: <http://www.wikidata.org/entity/>
    PREFIX wdt: <http://www.wikidata.org/prop/direct/>
    PREFIX p: <http://www.wikidata.org/prop/>
    PREFIX ps: <http://www.wikidata.org/prop/statement/>
    PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
    PREFIX wikibase: <http://wikiba.se/ontology#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  SPARQL

  # Run a SPARQL query against Wikidata, prepending the standard prefixes.
  #
  # @param [String] sparql the query body (without prefix declarations)
  # @return [Array<RDF::Query::Solution>]
  def self.query(sparql)
    client.query(PREFIXES + sparql)
  end

  # Build a SPARQL client pointed at the Wikidata endpoint.
  #
  # @return [SPARQL::Client]
  def self.client
    SPARQL::Client.new(
      ENDPOINT,
      method: :get,
      headers: { 'User-Agent': USER_AGENT },
      read_timeout: 300
    )
  end
end
