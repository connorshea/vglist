# frozen_string_literal: true

require 'sparql/client'

# Shared configuration for querying Wikidata over SPARQL.
#
# We query QLever's hosted Wikidata mirror
# (https://qlever.dev/wikidata) rather than the official Wikidata Query
# Service (WDQS). QLever is dramatically faster and has no query timeout. Its
# mirror is continuously updated and tracks Wikidata within hours (verified via
# the newest schema:dateModified in its data), so freshness is a non-issue for
# our import tasks.
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
  # deploy if QLever is ever unavailable.
  ENDPOINT = ENV.fetch('WIKIDATA_SPARQL_ENDPOINT', 'https://qlever.dev/api/wikidata')

  # Contact email advertised in the User-Agent per Wikimedia's user-agent
  # policy. Optional and unset by default — set WIKIDATA_CONTACT_EMAIL to
  # include a contact address (recommended when running imports in production).
  USER_AGENT = [
    'vglist Data Fetcher/1.0',
    ENV['WIKIDATA_CONTACT_EMAIL'].present? ? "(#{ENV['WIKIDATA_CONTACT_EMAIL']})" : nil,
    "Ruby #{RUBY_VERSION}"
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

  # Seconds to pause before every request, to proactively stay under QLever's
  # rate limit rather than only backing off once it returns a 429.
  INTER_QUERY_DELAY_SECONDS = 1

  # Seconds to wait before the first retry after a 429; doubles each attempt
  # (4, 8, 16, 32 seconds).
  INITIAL_BACKOFF_SECONDS = 4

  # Run a SPARQL query against Wikidata, prepending the standard prefixes.
  #
  # @param [String] sparql the query body (without prefix declarations)
  # @return [Array<RDF::Query::Solution>]
  def self.query(sparql)
    # Pace requests to stay under QLever's rate limit even when we're not
    # actively being throttled.
    sleep(INTER_QUERY_DELAY_SECONDS)
    with_retry { client.query(PREFIXES + sparql) }
  end

  # Retry a SPARQL request with exponential backoff when the endpoint
  # rate-limits us (HTTP 429). QLever's nginx returns 429 under bursts of rapid
  # queries (e.g. the chunked hydration in the games import); backing off clears
  # it. Other errors propagate immediately.
  #
  # @return [Array<RDF::Query::Solution>]
  def self.with_retry(max_attempts: 5)
    attempt = 0
    begin
      attempt += 1
      yield
    rescue SPARQL::Client::ClientError => e
      raise unless e.message.include?('429') && attempt < max_attempts

      backoff_seconds = INITIAL_BACKOFF_SECONDS * (2**(attempt - 1)) # 4, 8, 16, 32 seconds
      warn "SPARQL endpoint returned 429 (attempt #{attempt}/#{max_attempts}); retrying in #{backoff_seconds}s..."
      sleep(backoff_seconds)
      retry
    end
  end

  # Build a SPARQL client pointed at the Wikidata endpoint.
  #
  # Queries are sent via POST so they aren't constrained by the URL-length
  # ceiling a GET query string imposes on the VALUES clauses in the import
  # tasks. This lets us hydrate larger chunks per round-trip.
  #
  # @return [SPARQL::Client]
  def self.client
    SPARQL::Client.new(
      ENDPOINT,
      method: :post,
      headers: { 'User-Agent': USER_AGENT },
      read_timeout: 300
    )
  end
end
