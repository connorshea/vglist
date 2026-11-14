# frozen_string_literal: true

# The games whose covers make up a series', genre's, platform's, company's or
# engine's tile on its index page: up to four games that have a cover,
# most-owned first. Batched like `LazyOwnerCount`: every `coverGames` field in
# the response returns one of these, and the first to be resolved loads the
# covers for all the records of its kind queued so far, with one query for
# the game IDs and one preload of the games and their covers.
#
# Without this, a page of 24 tiles runs a `games(first: 4)` query plus the
# attachment and variant lookups for every tile, about 145 queries in all.
#
# Each record's game IDs are then cached for EXPIRES_IN, since finding them
# reads every game of a mid-sized genre or company along with its cover
# attachment (100-500ms for a page in production), and which games make up a
# tile only matters roughly. The games themselves are always loaded fresh.
class LazyCoverGames
  LIMIT = 4

  EXPIRES_IN = 6.hours

  # Records with at least this many games find their top games by walking
  # every game from most-owned down, stopping at the fourth of theirs with a
  # cover. In production that takes 1-50ms per record for one with a
  # thousand games or more (Windows: under 2ms), where ranking all of its
  # games took hundreds of milliseconds, and ranking a page of the biggest
  # platforms took 3 seconds. But a record with a few unowned games would walk
  # most of the games table to find them, so smaller records are still ranked
  # all together (about 200ms for a page of the smallest platforms, mostly
  # one pass over the cover attachments). Postgres plans a per-record
  # subquery once for every record, so it can't pick the approach itself.
  WALK_THRESHOLD = 1_000

  # Resource class => how to reach its games, and the column that names the
  # resource. `%<ids>s` in a subquery is replaced with the record condition.
  # Fixed SQL fragments, never user input.
  SOURCES = {
    'Series' => { from: 'games', key: 'games.series_id' },
    'Genre' => { from: 'game_genres JOIN games ON games.id = game_genres.game_id', key: 'game_genres.genre_id' },
    'Platform' => { from: 'game_platforms JOIN games ON games.id = game_platforms.game_id', key: 'game_platforms.platform_id' },
    'Engine' => { from: 'game_engines JOIN games ON games.id = game_engines.game_id', key: 'game_engines.engine_id' },
    # Developed or published, once per game. The condition goes inside the
    # union so that it only reads this page's companies.
    'Company' => {
      from: '(SELECT company_id, game_id FROM game_developers WHERE company_id %<ids>s ' \
            'UNION SELECT company_id, game_id FROM game_publishers WHERE company_id %<ids>s) company_games ' \
            'JOIN games ON games.id = company_games.game_id',
      key: 'company_games.company_id'
    }
  }.freeze

  COVER_JOIN = "JOIN active_storage_attachments cover " \
               "ON cover.record_type = 'Game' AND cover.record_id = games.id AND cover.name = 'cover'"

  def initialize(context, record)
    @kind = record.class.name
    @record_id = record.id
    states = context[:lazy_cover_games] ||= {}
    @state = states[@kind] ||= { pending: {}, loaded: {} }
    @state[:pending][@record_id] = games_count(record) unless @state[:loaded].key?(@record_id)
  end

  # @return [Array<Game>]
  def value
    load_pending unless @state[:loaded].key?(@record_id)
    @state[:loaded].fetch(@record_id)
  end

  private

  # The record's stored game count. Nil when the record was loaded without it.
  def games_count(record)
    record.games_count if record.has_attribute?(:games_count)
  end

  def load_pending
    ids = cover_game_ids(@state[:pending])
    games = Game.where(id: ids.values.flatten).with_attached_cover.index_by(&:id)

    # A cached game may have been deleted or lost its cover since.
    loaded = ids.transform_values do |game_ids|
      game_ids.filter_map { |id| games[id] if games[id]&.cover&.attached? }
              .sort_by { |game| [-game.game_purchases_count, game.id] }
    end
    @state[:loaded].merge!(loaded)
    @state[:pending].clear
  end

  # @param pending [Hash{Integer => Integer, nil}] Record ID => its game count.
  # @return [Hash{Integer => Array<Integer>}] Record ID => its top game IDs,
  #   from the cache where they're there and from the database otherwise.
  def cover_game_ids(pending)
    keys = pending.keys.index_by { |id| cache_key(id) }
    cached = Rails.cache.read_multi(*keys.keys).transform_keys(&keys)
    missing = pending.except(*cached.keys)
    return cached if missing.empty?

    big, small = missing.keys.partition { |id| missing[id].to_i >= WALK_THRESHOLD }
    rows = ActiveRecord::Base.connection.select_rows(top_games_sql(big, small))
    found = missing.keys.index_with { [] }
    rows.each { |record_id, game_id| found[record_id] << game_id }

    Rails.cache.write_multi(found.transform_keys { |id| cache_key(id) }, expires_in: EXPIRES_IN)
    cached.merge(found)
  end

  def cache_key(record_id)
    "cover_games/#{@kind}/#{record_id}"
  end

  # The top games per record, by the same owner counter cache as
  # `ResourceGameSort`'s most_owners order.
  def top_games_sql(big, small)
    branches = []
    branches << walk_sql if big.any?
    branches << ranking_sql if small.any?
    ActiveRecord::Base.sanitize_sql([branches.join(' UNION ALL '), { big: big, small: small, limit: LIMIT }])
  end

  # The first games of each big record in a walk of
  # `index_games_on_game_purchases_count_and_id`, read backwards.
  def walk_sql
    source = SOURCES.fetch(@kind)
    <<~SQL.squish
      SELECT r.id, top.game_id
      FROM unnest(ARRAY[:big]::bigint[]) AS r(id)
      CROSS JOIN LATERAL (
        SELECT games.id AS game_id
        FROM #{format(source[:from], ids: '= r.id')}
        #{COVER_JOIN}
        WHERE #{source[:key]} = r.id
        ORDER BY games.game_purchases_count DESC, games.id ASC
        LIMIT :limit
      ) top
    SQL
  end

  # Every game of the small records, ranked, keeping the top ones of each.
  def ranking_sql
    source = SOURCES.fetch(@kind)
    <<~SQL.squish
      SELECT ranked.record_id, ranked.game_id
      FROM (
        SELECT #{source[:key]} AS record_id, games.id AS game_id,
          ROW_NUMBER() OVER (
            PARTITION BY #{source[:key]}
            ORDER BY games.game_purchases_count DESC, games.id ASC
          ) AS position
        FROM #{format(source[:from], ids: 'IN (:small)')}
        #{COVER_JOIN}
        WHERE #{source[:key]} IN (:small)
      ) ranked
      WHERE ranked.position <= :limit
    SQL
  end
end
