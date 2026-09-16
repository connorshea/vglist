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
# How each state is detected (two plain-join SPARQL queries per chunk — see
# classify_chunk for why it isn't one):
#   * merged/redirected -> the item has an `owl:sameAs` triple pointing at the
#     item it was merged into (Wikidata leaves this behind on the old Q-id).
#   * deleted           -> the item has zero triples in the mirror.
#   * healthy           -> has triples and no `owl:sameAs`; not reported.
#
# Optional dump shortcut: pass WIKIDATA_DUMP_JSON pointing at the blob from
# script/dump_wikidata_games.rb and any vglist ID present in it — i.e. still a
# video game item on Wikidata — skips the live check entirely. Only IDs missing
# from the dump (deleted, merged/redirected, or no longer typed as a game) are
# queried against the endpoint, which is usually a tiny fraction of the library.
# The dump is a snapshot, so an item deleted after it was generated won't be
# caught until the dump is regenerated.
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
#   WIKIDATA_DUMP_JSON        optional path to the dump from dump_wikidata_games.rb;
#                             IDs found in it skip the live check (see below)
#
# Resilience and resume:
#   * Transient network failures (dropped connections, timeouts, TLS resets) and
#     gateway errors (429 rate limits, 502/503/504) are retried with backoff on
#     every request, so a blip doesn't abort a long run.
#   * The vglist fetch is written incrementally to two sidecar files next to
#     VGLIST_GAMES_JSON — "<name>.partial.jsonl" (one game per line, appended as
#     each page arrives) and "<name>.progress.json" (the pagination cursor). If
#     the fetch is interrupted, simply re-run: it resumes from the last saved
#     page instead of starting over. The sidecars are removed once the full
#     dataset has been written. Delete them by hand to force a fresh fetch.
#   * The Wikidata classification pass resumes the same way, via
#     "<name>.classify.partial.jsonl" (stale verdicts, appended per chunk) and
#     "<name>.classify.progress.json" (the last completed chunk, keyed to the ID
#     set). An interrupted classification re-run skips to the first unfinished
#     chunk rather than re-checking every ID. These are removed once it finishes.

require 'net/http'
require 'openssl'
require 'uri'
require 'json'
require 'time'
require 'digest'

module FindStaleWikidataIds
  VGLIST_ENDPOINT = ENV.fetch('VGLIST_ENDPOINT', 'https://vglist.co/graphql')
  SPARQL_ENDPOINT = ENV.fetch('WIKIDATA_SPARQL_ENDPOINT', 'https://qlever.dev/api/wikidata')
  CHUNK_SIZE = Integer(ENV.fetch('CHUNK_SIZE', '100'))
  PAGE_SIZE = 100 # vglist caps connections at 100 records per page.

  # Where the fetched vglist dataset is saved (and optionally reloaded from).
  GAMES_JSON = ENV.fetch('VGLIST_GAMES_JSON', 'vglist_games.json')

  # Optional path to the Wikidata games dump produced by
  # script/dump_wikidata_games.rb. When set, any vglist Wikidata ID present in
  # the dump is known to still exist as a video game and skips the live QLever
  # check; only IDs absent from the dump are classified against the endpoint.
  WIKIDATA_DUMP_JSON = ENV['WIKIDATA_DUMP_JSON'].to_s.strip.freeze

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

    # An ID present in the Wikidata dump still exists as a video game, so it can't
    # be stale — only IDs missing from the dump need the live QLever check.
    ids_to_check = ids
    unless WIKIDATA_DUMP_JSON.empty?
      present = load_dump_ids(WIKIDATA_DUMP_JSON)
      ids_to_check = ids.reject { |id| present[id] }
      warn "#{ids.length - ids_to_check.length} of #{ids.length} IDs are present in the dump " \
           "(#{WIKIDATA_DUMP_JSON}) and skip the live check; #{ids_to_check.length} to verify live."
    end

    warn "Checking #{ids_to_check.length} distinct Wikidata IDs against #{SPARQL_ENDPOINT} ..."
    states = classify_wikidata_ids(ids_to_check)
    clear_classify_progress

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

  # Numeric Wikidata IDs present in the dump, as a { id => true } lookup.
  #
  # The dump writes one game object per line, led by its "wikidata_id" key, so we
  # pull just that first field with a regex rather than JSON-parsing each line —
  # the full per-game property payload is large and we only need the ID. Works on
  # both the final blob (indented, comma-terminated lines) and the raw
  # ".partial.jsonl" sidecar; any game line not led by wikidata_id falls back to
  # a full parse.
  def load_dump_ids(path)
    raise "Wikidata dump not found: #{path}" unless File.exist?(path)

    present = {}
    File.foreach(path) do |line|
      if (match = line.match(/\A\s*\{"wikidata_id":(\d+)/))
        present[match[1].to_i] = true
      elsif line.lstrip.start_with?('{"')
        id = JSON.parse(line.strip.chomp(','))['wikidata_id']
        present[id] = true if id
      end
    end
    warn "Loaded #{present.size} Wikidata IDs from the dump (#{path})."
    present
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

  # Classify every given numeric Wikidata ID and return only the stale ones, as a
  # Hash: { 6789 => [:deleted, nil], 999 => [:merged, 179] }. Healthy (:ok) IDs
  # are the overwhelming majority and the caller ignores them, so they're neither
  # returned nor stored — this keeps memory flat and makes a resumed run's result
  # identical to an uninterrupted one.
  #
  # Chunk-level resume: after each chunk, the stale verdicts are appended to a
  # JSONL sidecar and the completed chunk index recorded in a progress file, both
  # keyed to the exact ID set. An interrupted run re-reads them and skips straight
  # to the first unfinished chunk instead of re-querying every ID again. The
  # sidecars are cleared once the run finishes.
  def classify_wikidata_ids(ids)
    partial, progress = classify_paths
    fingerprint = ids_fingerprint(ids)
    start_chunk = resume_classify_chunk(progress, ids.length, fingerprint)

    states = start_chunk.positive? ? load_classified(partial) : {}
    chunks = ids.each_slice(CHUNK_SIZE).to_a
    if start_chunk.positive?
      warn "Resuming classification from chunk #{start_chunk + 1}/#{chunks.length} " \
           "(#{states.length} stale ID(s) already found)."
    end

    File.open(partial, start_chunk.positive? ? 'a' : 'w') do |file|
      chunks.each_with_index do |chunk, index|
        next if index < start_chunk

        classify_chunk(chunk).each do |id, (state, merged_into)|
          next if state == :ok # healthy IDs are neither returned nor persisted

          states[id] = [state, merged_into]
          file.puts JSON.generate('id' => id, 'state' => state, 'merged_into' => merged_into)
        end
        file.flush
        write_classify_checkpoint(progress, chunk_index: index, total: ids.length, fingerprint: fingerprint)

        done = [(index + 1) * CHUNK_SIZE, ids.length].min
        warn "  chunk #{index + 1}/#{chunks.length} (#{done}/#{ids.length}) ..." if (index % 10).zero?
      end
    end

    states
  end

  # Classify a chunk of Wikidata IDs with two cheap, plain-join queries.
  #
  # These used to be one query with `OPTIONAL { ?item ?p ?o }` to count triples,
  # but that unbound-predicate optional makes QLever plan a full scan of the SPO
  # index (billions of rows) and the server OOMs ("Tried to allocate ... but only
  # ... available"). Instead we ask separately: (a) which items redirect via
  # owl:sameAs, and (b) which items still have any triple at all. Both bind
  # ?item through VALUES first, so each scans only the ~100 items in the chunk.
  # An item that has no triples and isn't a redirect is a deletion.
  def classify_chunk(chunk)
    merges = fetch_merge_targets(chunk)
    existing = fetch_existing_ids(chunk)

    chunk.each_with_object({}) do |id, states|
      if (target = merges[id])
        states[id] = [:merged, target]
      elsif !existing[id]
        states[id] = [:deleted, nil]
      else
        states[id] = [:ok, nil]
      end
    end
  end

  # Items in the chunk that redirect to another Wikidata item, as
  # { id => target_id }. owl:sameAs can also point at external entities (e.g.
  # Freebase); only a target in Wikidata's entity namespace signals a merge.
  def fetch_merge_targets(chunk)
    query = <<~SPARQL
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT ?item ?target WHERE {
        VALUES ?item { #{item_values(chunk)} }
        ?item owl:sameAs ?target.
        FILTER(STRSTARTS(STR(?target), "http://www.wikidata.org/entity/Q"))
      }
    SPARQL

    sparql_query(query).dig('results', 'bindings').each_with_object({}) do |binding, targets|
      id = qid_to_int(binding.dig('item', 'value'))
      target = qid_to_int(binding.dig('target', 'value'))
      # Guard both ends: a non-Q-ID target must never leave merged_into nil (the
      # %d format in #report would raise on that).
      targets[id] = target if id && target
    end
  end

  # The subset of the chunk that still has at least one statement in the mirror,
  # as a { id => true } lookup. Any chunk id absent from the result has no
  # statements, i.e. was deleted.
  #
  # We match direct-claim (wdt:) statements via `wikibase:directClaim` rather
  # than every triple (`?item ?p ?o`): a plain all-triples scan pulls each item's
  # hundreds of labels/descriptions/aliases/sitelinks, and materializing that for
  # 100 items is heavy enough to time the upstream out (nginx 502). This is the
  # same bounded pattern the dumper uses; a live game always has statements.
  def fetch_existing_ids(chunk)
    query = <<~SPARQL
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wikibase: <http://wikiba.se/ontology#>
      SELECT DISTINCT ?item WHERE {
        VALUES ?item { #{item_values(chunk)} }
        ?item ?propUrl ?value.
        ?prop wikibase:directClaim ?propUrl.
      }
    SPARQL

    sparql_query(query).dig('results', 'bindings').each_with_object({}) do |binding, existing|
      id = qid_to_int(binding.dig('item', 'value'))
      existing[id] = true if id
    end
  end

  # A space-separated `wd:Q…` list for a VALUES clause.
  def item_values(chunk)
    chunk.map { |id| "wd:Q#{id}" }.join(' ')
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

      # Gateway errors (nginx 502/503/504) mean the upstream QLever hiccuped or
      # timed out — transient, so back off and retry rather than aborting a long
      # run. (A genuine query error comes back as 500 with a JSON `exception`
      # body, handled below, and is not retried here.)
      if %w[502 503 504].include?(response.code) && attempt < MAX_SPARQL_ATTEMPTS
        backoff = INITIAL_BACKOFF_SECONDS * (2**(attempt - 1))
        warn "  gateway error (HTTP #{response.code}); retrying in #{backoff}s"
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

  # ---- Resumable classification bookkeeping ----------------------------------
  #
  # Sidecars next to GAMES_JSON, distinct from the fetch ones: the stale verdicts
  # as JSONL (appended per chunk) and the last completed chunk index as JSON.

  def classify_paths
    ["#{GAMES_JSON}.classify.partial.jsonl", "#{GAMES_JSON}.classify.progress.json"]
  end

  # A stable digest of the exact ID set (and order) being classified. If the
  # dataset changes between runs the chunk boundaries shift, so a mismatch
  # forces classification to start over rather than resume against stale offsets.
  def ids_fingerprint(ids)
    Digest::SHA1.hexdigest(ids.join(','))
  end

  # The next chunk index to classify: the one after the last completed chunk,
  # but only when a checkpoint and partial file exist and still match this run's
  # chunk size and ID set. Otherwise 0 (start over).
  def resume_classify_chunk(progress, total, fingerprint)
    partial, = classify_paths
    return 0 unless File.exist?(progress) && File.exist?(partial)

    checkpoint = parse_json(File.read(progress))
    return 0 unless checkpoint['chunk_size'] == CHUNK_SIZE &&
                    checkpoint['total'] == total &&
                    checkpoint['fingerprint'] == fingerprint

    checkpoint['chunk_index'].to_i + 1
  rescue StandardError => e
    warn "Ignoring unreadable classification checkpoint #{progress}: #{e.message}"
    0
  end

  def write_classify_checkpoint(path, chunk_index:, total:, fingerprint:)
    File.write(path, JSON.generate(
                       'chunk_index' => chunk_index,
                       'chunk_size' => CHUNK_SIZE,
                       'total' => total,
                       'fingerprint' => fingerprint,
                       'endpoint' => SPARQL_ENDPOINT,
                       'updated_at' => Time.now.utc.iso8601
                     ))
  end

  # Rebuild the stale-verdict states from the JSONL sidecar, tolerating a
  # truncated final line left by a crash mid-write. Only non-:ok verdicts are
  # stored, which is all the caller needs.
  def load_classified(path)
    states = {}
    File.foreach(path).with_index do |line, index|
      line = line.strip
      next if line.empty?

      begin
        record = JSON.parse(line)
      rescue JSON::ParserError
        warn "  skipping unparseable line #{index + 1} in #{path} (likely a partial write before a crash)"
        next
      end

      id = record['id']
      next unless id

      states[id] = [record['state'].to_s.to_sym, record['merged_into']]
    end
    states
  end

  def clear_classify_progress
    classify_paths.each { |path| File.delete(path) if File.exist?(path) }
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
