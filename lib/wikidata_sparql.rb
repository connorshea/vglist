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

  # Seconds to wait before the first retry when QLever rejects a query because
  # all of its query-processing threads are busy; doubles each attempt (15, 30,
  # 60, 120 seconds). This is longer than the 429 backoff because a saturated
  # server needs time to drain its queue, and hammering it sooner would only add
  # to the load.
  BUSY_INITIAL_BACKOFF_SECONDS = 15

  # Substring of the error QLever returns when every query-processing thread was
  # busy for longer than its `query-queue-max-wait`. The body asks clients to
  # "retry later", so it's transient and safe to retry.
  BUSY_ERROR_MESSAGE = 'threads for processing queries were busy'

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

  # Retry a SPARQL request with exponential backoff when the endpoint tells us
  # to come back later:
  #
  #   * HTTP 429: QLever's nginx rate-limits bursts of rapid queries (e.g. the
  #     chunked hydration in the games import).
  #   * "All N threads for processing queries were busy": QLever is saturated
  #     by other users' queries and rejected ours without running it.
  #
  # Both clear up after backing off. Attempts are capped, so a persistently
  # overloaded server still fails the task rather than being retried forever.
  # Other errors propagate immediately.
  #
  # @return [Array<RDF::Query::Solution>]
  def self.with_retry(max_attempts: 5)
    attempt = 0
    begin
      attempt += 1
      yield
    rescue SPARQL::Client::ClientError => e
      initial_backoff, reason = retryable_error(e)
      raise unless initial_backoff && attempt < max_attempts

      backoff_seconds = initial_backoff * (2**(attempt - 1))
      warn "SPARQL endpoint #{reason} (attempt #{attempt}/#{max_attempts}); retrying in #{backoff_seconds}s..."
      sleep(backoff_seconds)
      retry
    end
  end

  # Classify a SPARQL client error as retryable or not.
  #
  # @param [SPARQL::Client::ClientError] error
  # @return [Array(Integer, String), nil] the initial backoff in seconds and a
  #   description for the log line, or nil if the error shouldn't be retried.
  def self.retryable_error(error)
    if error.message.include?(BUSY_ERROR_MESSAGE)
      [BUSY_INITIAL_BACKOFF_SECONDS, 'was too busy to accept the query']
    elsif error.message.include?('429')
      [INITIAL_BACKOFF_SECONDS, 'returned 429']
    end
  end
  private_class_method :retryable_error

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
