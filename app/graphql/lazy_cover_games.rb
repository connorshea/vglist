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
class LazyCoverGames
  LIMIT = 4

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

  # The record's stored game count, or its `index_games_count` for companies
  # (which have no column) when the list loaded one. Nil when unknown.
  def games_count(record)
    return record.games_count if record.has_attribute?(:games_count)

    record.attributes['index_games_count']
  end

  def load_pending
    big, small = @state[:pending].keys.partition { |id| @state[:pending][id].to_i >= WALK_THRESHOLD }
    rows = ActiveRecord::Base.connection.select_rows(top_games_sql(big, small))
    games = Game.where(id: rows.map(&:second)).with_attached_cover.index_by(&:id)

    loaded = @state[:pending].keys.index_with { [] }
    rows.each { |record_id, game_id| loaded[record_id] << games.fetch(game_id) }
    # The union's rows come back in no particular order.
    loaded.each_value { |list| list.sort_by! { |game| [-game.game_purchases_count, game.id] } }
    @state[:loaded].merge!(loaded)
    @state[:pending].clear
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
