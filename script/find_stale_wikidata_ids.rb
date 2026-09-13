#!/usr/bin/env ruby
# frozen_string_literal: true

# Find vglist games whose Wikidata item no longer exists or was merged.
#
# This is a standalone client — it does NOT need the Rails app or a database.
# It pulls every game from vglist.co's GraphQL API — name, wikidataId, release
# date, and external IDs (IGDB, Steam App IDs, MobyGames), all saved to the
# dataset JSON — then asks QLever's Wikidata mirror (the same endpoint the import
# rake tasks use) which of those Wikidata items have since been deleted or
# merged/redirected into another item. Both cases mean the stored wikidataId is
# stale.
#
# How each state is detected in one SPARQL query per chunk:
#   * merged/redirected -> the item has an `owl:sameAs` triple pointing at the
#     item it was merged into (Wikidata leaves this behind on the old Q-id).
#   * deleted           -> the item has zero triples in the mirror.
#   * healthy           -> has triples and no `owl:sameAs`; not reported.
#
# Usage:
#   VGLIST_EMAIL=you@example.com VGLIST_TOKEN=your_api_token \
#     ruby script/find_stale_wikidata_ids.rb
#
# Environment variables:
#   VGLIST_EMAIL              (required) email of your vglist account
#   VGLIST_TOKEN              (required) your vglist API token (Settings -> API)
#   VGLIST_ENDPOINT           GraphQL endpoint (default https://vglist.co/graphql)
#   WIKIDATA_SPARQL_ENDPOINT  SPARQL endpoint (default https://qlever.dev/api/wikidata;
#                             set to https://query.wikidata.org/sparql to use WDQS)
#   WIKIDATA_CONTACT_EMAIL    optional contact address added to the SPARQL User-Agent
#   CHUNK_SIZE                Wikidata IDs per SPARQL query (default 100)
#   OUTPUT_CSV                optional path; also writes the findings as CSV
#   VGLIST_GAMES_JSON         where to save the fetched dataset (default vglist_games.json)
#   USE_CACHE                 if set (e.g. USE_CACHE=1), reuse VGLIST_GAMES_JSON instead
#                             of re-fetching from the API when the file already exists
#
# Resilience and resume:
#   * Transient network failures (dropped connections, timeouts, TLS resets) are
#     retried with backoff on every request, so a blip doesn't abort a long run.
#   * The vglist fetch is written incrementally to two sidecar files next to
#     VGLIST_GAMES_JSON — "<name>.partial.jsonl" (one game per line, appended as
#     each page arrives) and "<name>.progress.json" (the pagination cursor). If
#     the fetch is interrupted, simply re-run: it resumes from the last saved
#     page instead of starting over. The sidecars are removed once the full
#     dataset has been written. Delete them by hand to force a fresh fetch.

require 'net/http'
require 'openssl'
require 'uri'
require 'json'
require 'time'

module FindStaleWikidataIds
  VGLIST_ENDPOINT = ENV.fetch('VGLIST_ENDPOINT', 'https://vglist.co/graphql')
  SPARQL_ENDPOINT = ENV.fetch('WIKIDATA_SPARQL_ENDPOINT', 'https://qlever.dev/api/wikidata')
  CHUNK_SIZE = Integer(ENV.fetch('CHUNK_SIZE', '100'))
  PAGE_SIZE = 100 # vglist caps connections at 100 records per page.

  # Where the fetched vglist dataset is saved (and optionally reloaded from).
  GAMES_JSON = ENV.fetch('VGLIST_GAMES_JSON', 'vglist_games.json')

  # Pace SPARQL requests to stay under QLever's rate limit, and back off on 429.
  # Mirrors lib/wikidata_sparql.rb's approach.
  INTER_QUERY_DELAY_SECONDS = 1
  INITIAL_BACKOFF_SECONDS = 4
  MAX_SPARQL_ATTEMPTS = 5

  # Retry transient network failures on any request so a single dropped
  # connection or TLS reset doesn't abort a long-running fetch.
  MAX_NETWORK_ATTEMPTS = 6
  TRANSIENT_NETWORK_ERRORS = [
    Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
    Errno::ENETUNREACH, Errno::ETIMEDOUT, Errno::EPIPE,
    Net::OpenTimeout, Net::ReadTimeout,
    OpenSSL::SSL::SSLError, EOFError, SocketError, IOError
  ].freeze

  USER_AGENT = [
    'vglist stale-wikidata checker/1.0',
    ENV['WIKIDATA_CONTACT_EMAIL'].to_s.empty? ? nil : "(#{ENV['WIKIDATA_CONTACT_EMAIL']})",
    "Ruby #{RUBY_VERSION}"
  ].compact.join(' ')

  # A game from vglist whose wikidataId turned out to be stale.
  Finding = Struct.new(:game_id, :name, :wikidata_id, :state, :merged_into, keyword_init: true)

  module_function

  def run
    games =
      if reuse_cache?
        warn "Loading cached dataset from #{GAMES_JSON} (USE_CACHE set) ..."
        load_games(GAMES_JSON)
      else
        email = require_env('VGLIST_EMAIL')
        token = require_env('VGLIST_TOKEN')
        warn "Fetching games from #{VGLIST_ENDPOINT} ..."
        fetched = fetch_all_games(email: email, token: token)
        save_games(fetched, GAMES_JSON)
        clear_fetch_progress
        fetched
      end

    with_wikidata = games.select { |g| g[:wikidata_id] }
    warn "#{games.length} games total; #{with_wikidata.length} have a Wikidata ID."

    # A Wikidata ID can (rarely) be attached to more than one game, so map each
    # ID back to every game that points at it.
    games_by_wikidata_id = Hash.new { |h, k| h[k] = [] }
    with_wikidata.each { |g| games_by_wikidata_id[g[:wikidata_id]] << g }
    ids = games_by_wikidata_id.keys

    warn "Checking #{ids.length} distinct Wikidata IDs against #{SPARQL_ENDPOINT} ..."
    states = classify_wikidata_ids(ids)

    findings = []
    states.each do |wikidata_id, (state, merged_into)|
      next if state == :ok

      games_by_wikidata_id[wikidata_id].each do |game|
        findings << Finding.new(
          game_id: game[:id],
          name: game[:name],
          wikidata_id: wikidata_id,
          state: state,
          merged_into: merged_into
        )
      end
    end

    report(findings, checked: ids.length)
    write_csv(findings, ENV['OUTPUT_CSV']) if ENV['OUTPUT_CSV']
  end

  # ---- vglist GraphQL --------------------------------------------------------

  GAMES_QUERY = <<~GRAPHQL.freeze
    query($after: String) {
      games(first: #{PAGE_SIZE}, after: $after) {
        totalCount
        nodes { id name wikidataId releaseDate igdbId steamAppIds mobygamesId }
        pageInfo { endCursor hasNextPage }
      }
    }
  GRAPHQL

  # Map a node (from the GraphQL response or a saved JSON record — both use the
  # API's camelCase keys) to the symbol-keyed shape the rest of the script uses.
  def node_to_game(node)
    {
      id: node['id'],
      name: node['name'],
      wikidata_id: node['wikidataId'],
      release_date: node['releaseDate'],
      igdb_id: node['igdbId'],
      steam_app_ids: node['steamAppIds'] || [],
      mobygames_id: node['mobygamesId']
    }
  end

  # Inverse of #node_to_game: a camelCase, string-keyed record for persistence.
  def game_to_json(game)
    {
      'id' => game[:id],
      'name' => game[:name],
      'wikidataId' => game[:wikidata_id],
      'releaseDate' => game[:release_date],
      'igdbId' => game[:igdb_id],
      'steamAppIds' => game[:steam_app_ids] || [],
      'mobygamesId' => game[:mobygames_id]
    }
  end

  def fetch_all_games(email:, token:)
    partial, progress = progress_paths
    checkpoint = load_checkpoint(progress)
    resuming = checkpoint && checkpoint['endpoint'] == VGLIST_ENDPOINT && File.exist?(partial)

    games = []
    after = nil
    page = 0

    if resuming
      games = load_partial(partial)
      after = checkpoint['after']
      page = checkpoint['page'].to_i
      warn "Resuming fetch from page #{page} (#{games.length} games already saved in #{partial}) ..."
    end

    # Append each page to the JSONL sidecar and record the cursor after every
    # page, so an interrupted run resumes here instead of refetching from page 1.
    File.open(partial, resuming ? 'a' : 'w') do |file|
      file.puts if resuming # clean line boundary after any half-written page

      loop do
        body = graphql_request(email: email, token: token, variables: { after: after })
        conn = body.dig('data', 'games')
        raise "Unexpected GraphQL response: #{body.inspect}" if conn.nil?

        conn['nodes'].each do |node|
          game = node_to_game(node)
          games << game
          file.puts JSON.generate(game_to_json(game))
        end
        file.flush

        page += 1
        after = conn.dig('pageInfo', 'endCursor')
        write_checkpoint(progress, after: after, page: page, total_count: conn['totalCount'])
        warn "  page #{page}: #{games.length}/#{conn['totalCount']} games" if (page % 10).zero?

        break unless conn.dig('pageInfo', 'hasNextPage')
      end
    end

    # A page may have been re-fetched if a crash landed between saving it and
    # writing the checkpoint; drop any duplicate game IDs.
    games.uniq { |g| g[:id] }
  end

  # Save the fetched dataset as a JSON blob: a bit of metadata plus the games,
  # so a later run can reuse it (USE_CACHE) without re-hitting the API.
  def save_games(games, path)
    blob = {
      'fetched_at' => Time.now.utc.iso8601,
      'endpoint' => VGLIST_ENDPOINT,
      'game_count' => games.length,
      'games' => games.map { |g| game_to_json(g) }
    }
    File.write(path, JSON.pretty_generate(blob))
    warn "Saved #{games.length} games to #{path}"
  end

  # Load a dataset previously written by #save_games, normalizing back to the
  # symbol-keyed shape the rest of the script uses.
  def load_games(path)
    blob = parse_json(File.read(path))
    games = blob.is_a?(Hash) ? blob['games'] : blob # tolerate a bare array too
    raise "No games found in #{path}" unless games.is_a?(Array)

    games.map { |g| node_to_game(g) }
  end

  def reuse_cache?
    !ENV['USE_CACHE'].to_s.strip.empty? && File.exist?(GAMES_JSON)
  end

  def graphql_request(email:, token:, variables:)
    uri = URI.parse(VGLIST_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['X-User-Email'] = email
    request['X-User-Token'] = token
    request.body = JSON.generate(query: GAMES_QUERY, variables: variables)

    response = perform_http(uri, request, description: 'vglist GraphQL')
    body = parse_json(response.body)

    # The API's request-level auth failures come back as {"error":{"message":...}}
    # rather than as standard GraphQL {"errors":[...]}.
    raise "vglist API error (HTTP #{response.code}): #{body.dig('error', 'message') || body['error']}" if body.is_a?(Hash) && body['error']
    # body['errors'] is a plain Array of Hashes and this standalone script
    # doesn't load ActiveSupport, so Enumerable#pluck isn't available here.
    raise "vglist GraphQL errors: #{body['errors'].map { |e| e['message'] }.join('; ')}" if body.is_a?(Hash) && body['errors'] # rubocop:disable Rails/Pluck
    raise "vglist API HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    body
  end

  # ---- Wikidata / QLever -----------------------------------------------------

  # Classify every given numeric Wikidata ID. Returns a Hash:
  #   { 12345 => [:ok, nil], 6789 => [:deleted, nil], 999 => [:merged, 179] }
  def classify_wikidata_ids(ids)
    states = {}

    ids.each_slice(CHUNK_SIZE).with_index do |chunk, index|
      warn "  chunk #{index + 1} (#{index * CHUNK_SIZE + chunk.length}/#{ids.length}) ..." if (index % 10).zero?
      classify_chunk(chunk).each { |id, state| states[id] = state }
    end

    states
  end

  # One SPARQL query per chunk. Every VALUES item comes back as exactly one row
  # (thanks to the OPTIONALs + GROUP BY), so we can read each item's state
  # directly rather than inferring "absent means healthy".
  def classify_chunk(chunk)
    values = chunk.map { |id| "wd:Q#{id}" }.join(' ')
    query = <<~SPARQL
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT ?item ?target (COUNT(?o) AS ?triples) WHERE {
        VALUES ?item { #{values} }
        OPTIONAL { ?item owl:sameAs ?target. }
        OPTIONAL { ?item ?p ?o. }
      } GROUP BY ?item ?target
    SPARQL

    result = sparql_query(query)

    result.dig('results', 'bindings').each_with_object({}) do |binding, states|
      id = qid_to_int(binding.dig('item', 'value'))
      next unless id

      if binding['target']
        states[id] = [:merged, qid_to_int(binding.dig('target', 'value'))]
      elsif binding.dig('triples', 'value').to_i.zero?
        states[id] = [:deleted, nil]
      else
        states[id] = [:ok, nil]
      end
    end
  end

  def sparql_query(query)
    uri = URI.parse(SPARQL_ENDPOINT)
    attempt = 0

    begin
      attempt += 1
      sleep(INTER_QUERY_DELAY_SECONDS)

      request = Net::HTTP::Post.new(uri)
      request['Accept'] = 'application/sparql-results+json'
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['User-Agent'] = USER_AGENT
      request.set_form_data('query' => query)

      response = perform_http(uri, request, description: 'SPARQL')

      if response.code == '429' && attempt < MAX_SPARQL_ATTEMPTS
        backoff = INITIAL_BACKOFF_SECONDS * (2**(attempt - 1))
        warn "  rate limited (429); retrying in #{backoff}s"
        sleep(backoff)
        raise Retry
      end
      raise "SPARQL HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      body = parse_json(response.body)
      raise "SPARQL error: #{body['exception']}" if body['exception']

      body
    rescue Retry
      retry
    end
  end

  # ---- Output ----------------------------------------------------------------

  def report(findings, checked:)
    merged = findings.select { |f| f.state == :merged }
    deleted = findings.select { |f| f.state == :deleted }

    puts
    puts '=' * 72
    puts "Checked #{checked} distinct Wikidata IDs."
    puts "Stale: #{findings.length} game(s) — #{merged.length} merged, #{deleted.length} deleted."
    puts '=' * 72

    unless merged.empty?
      puts "\nMERGED / REDIRECTED (Wikidata ID now points elsewhere):"
      merged.sort_by(&:wikidata_id).each do |f|
        puts format('  game %<game_id>-8s Q%<wikidata_id>-10d -> Q%<merged_into>-10d  %<name>s',
                    game_id: f.game_id, wikidata_id: f.wikidata_id, merged_into: f.merged_into, name: f.name)
        puts "    https://www.wikidata.org/wiki/Q#{f.wikidata_id} (redirects to Q#{f.merged_into})"
      end
    end

    unless deleted.empty?
      puts "\nDELETED (Wikidata item no longer exists):"
      deleted.sort_by(&:wikidata_id).each do |f|
        puts format('  game %<game_id>-8s Q%<wikidata_id>-10d  %<name>s', game_id: f.game_id, wikidata_id: f.wikidata_id, name: f.name)
      end
    end

    puts "\nNo stale Wikidata IDs found. 🎉" if findings.empty?
  end

  def write_csv(findings, path)
    rows = findings.map do |f|
      [f.game_id, f.name, "Q#{f.wikidata_id}", f.state, f.merged_into ? "Q#{f.merged_into}" : nil]
    end
    File.open(path, 'w') do |file|
      file.puts csv_line(%w[game_id name wikidata_id state merged_into])
      rows.each { |row| file.puts csv_line(row) }
    end
    warn "Wrote #{findings.length} rows to #{path}"
  end

  # Minimal RFC-4180 CSV formatting so we don't depend on the csv gem.
  def csv_line(fields)
    fields.map do |field|
      value = field.to_s
      value.match?(/[",\n]/) ? %("#{value.gsub('"', '""')}") : value
    end.join(',')
  end

  # ---- Helpers ---------------------------------------------------------------

  Retry = Class.new(StandardError)

  def http_start(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 15
    http.read_timeout = 120
    http
  end

  # Perform an HTTP request, retrying transient network failures with backoff.
  def perform_http(uri, request, description:)
    with_network_retry(description) { http_start(uri).request(request) }
  end

  def with_network_retry(description)
    attempt = 0
    begin
      attempt += 1
      yield
    rescue *TRANSIENT_NETWORK_ERRORS => e
      raise if attempt >= MAX_NETWORK_ATTEMPTS

      backoff = [2**attempt, 60].min # 2, 4, 8, 16, 32, 60
      warn "  #{description} network error (attempt #{attempt}/#{MAX_NETWORK_ATTEMPTS}): " \
           "#{e.class}: #{e.message}; retrying in #{backoff}s"
      sleep(backoff)
      retry
    end
  end

  # ---- Resumable fetch bookkeeping -------------------------------------------
  #
  # The fetch is written to two sidecars next to GAMES_JSON so an interrupted
  # run can resume: the games as JSONL (appended per page) and the pagination
  # cursor as JSON (rewritten per page).

  def progress_paths
    ["#{GAMES_JSON}.partial.jsonl", "#{GAMES_JSON}.progress.json"]
  end

  def load_checkpoint(path)
    return nil unless File.exist?(path)

    parse_json(File.read(path))
  rescue StandardError => e
    warn "Ignoring unreadable checkpoint #{path}: #{e.message}"
    nil
  end

  def write_checkpoint(path, after:, page:, total_count:)
    File.write(path, JSON.generate(
                       'endpoint' => VGLIST_ENDPOINT,
                       'after' => after,
                       'page' => page,
                       'total_count' => total_count,
                       'updated_at' => Time.now.utc.iso8601
                     ))
  end

  # Read a partially-fetched dataset back from the JSONL sidecar, tolerating a
  # truncated final line left behind by a crash mid-write.
  def load_partial(path)
    games = []
    File.foreach(path).with_index do |line, index|
      line = line.strip
      next if line.empty?

      begin
        node = JSON.parse(line)
      rescue JSON::ParserError
        warn "  skipping unparseable line #{index + 1} in #{path} (likely a partial write before a crash)"
        next
      end
      games << node_to_game(node)
    end
    games
  end

  def clear_fetch_progress
    progress_paths.each { |path| File.delete(path) if File.exist?(path) }
  end

  def parse_json(body)
    JSON.parse(body)
  rescue JSON::ParserError => e
    raise "Could not parse response as JSON (#{e.message}): #{body.to_s[0, 200]}"
  end

  # "http://www.wikidata.org/entity/Q42" -> 42
  def qid_to_int(uri)
    match = uri.to_s.match(%r{/Q(\d+)\z})
    match && match[1].to_i
  end

  def require_env(name)
    value = ENV[name].to_s.strip
    return value unless value.empty?

    abort "Missing required environment variable: #{name}"
  end
end

FindStaleWikidataIds.run if $PROGRAM_NAME == __FILE__
