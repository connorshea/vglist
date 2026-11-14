# frozen_string_literal: true

require 'sparql/client'

# Shared configuration for querying Wikidata over SPARQL.
#
# We query WDQS v2 (https://query-next.wikidata.org), the QLever instance that
# Wikidata hosts itself, rather than the legacy Blazegraph-based Wikidata Query
# Service. QLever is dramatically faster than Blazegraph and has no practical
# query timeout for our imports.
#
# Programmatic access requires a specific User-Agent header, which we keep out
# of the codebase: it's read from the WIKIDATA_QUERY_USER_AGENT env var, and
# querying without it raises MissingUserAgentError.
#
# Two things differ from legacy WDQS, and the queries in lib/tasks/import are
# written with them in mind:
#
#   * QLever does not implicitly define the standard Wikidata prefixes, so every
#     query is prefixed with PREFIXES below (WDQS injects these for you).
#   * QLever doesn't support Blazegraph-specific extensions, so queries avoid the
#     `wikibase:label` service and `with { ... } as %name` named subqueries.
module WikidataSparql
  # The SPARQL endpoint to query. Override with the WIKIDATA_SPARQL_ENDPOINT env
  # var to point at another QLever Wikidata endpoint without a deploy.
  ENDPOINT = ENV.fetch('WIKIDATA_SPARQL_ENDPOINT', 'https://query-next.wikidata.org/sparql')

  # Env var holding the User-Agent header sent with every query. The endpoint
  # only accepts programmatic requests with this header, and its value must
  # never be committed, so there's deliberately no default.
  USER_AGENT_ENV_VAR = 'WIKIDATA_QUERY_USER_AGENT'

  # Raised when a query is attempted without WIKIDATA_QUERY_USER_AGENT set.
  class MissingUserAgentError < StandardError; end

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
    # Fail fast, before pacing, if the User-Agent isn't configured.
    agent = user_agent

    # Pace requests to stay under QLever's rate limit even when we're not
    # actively being throttled.
    sleep(INTER_QUERY_DELAY_SECONDS)
    with_retry { client(user_agent: agent).query(PREFIXES + sparql) }
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

  # The User-Agent header to send, from WIKIDATA_QUERY_USER_AGENT.
  #
  # @raise [MissingUserAgentError] if the env var is unset or blank
  # @return [String]
  def self.user_agent
    ENV[USER_AGENT_ENV_VAR].presence || raise(
      MissingUserAgentError,
      "#{USER_AGENT_ENV_VAR} is not set. The Wikidata query service (#{ENDPOINT}) " \
      "requires it as the User-Agent header for programmatic access. Set it and try again."
    )
  end

  # Build a SPARQL client pointed at the Wikidata endpoint.
  #
  # Queries are sent via POST so they aren't constrained by the URL-length
  # ceiling a GET query string imposes on the VALUES clauses in the import
  # tasks. This lets us hydrate larger chunks per round-trip.
  #
  # @param [String] user_agent the User-Agent header to send
  # @return [SPARQL::Client]
  def self.client(user_agent: self.user_agent)
    SPARQL::Client.new(
      ENDPOINT,
      method: :post,
      headers: { 'User-Agent': user_agent },
      read_timeout: 300
    )
  end
end
