# frozen_string_literal: true

# The games whose covers make up a series', genre's or platform's tile on its
# index page: up to four games that have a cover, most-owned first. Batched
# like `LazyOwnerCount`: every `coverGames` field in the response returns one
# of these, and the first to be resolved loads the covers for all the records
# of its kind queued so far, with one ranking query and one preload of the
# games and their covers.
#
# Without this, a page of 24 tiles runs a `games(first: 4)` query plus the
# attachment and variant lookups for every tile, about 145 queries in all.
class LazyCoverGames
  LIMIT = 4

  # Resource class => how to reach its games, and the column that names the
  # resource. Both are fixed SQL fragments, never user input.
  SOURCES = {
    'Series' => { from: 'games', key: 'games.series_id' },
    'Genre' => { from: 'game_genres JOIN games ON games.id = game_genres.game_id', key: 'game_genres.genre_id' },
    'Platform' => { from: 'game_platforms JOIN games ON games.id = game_platforms.game_id', key: 'game_platforms.platform_id' }
  }.freeze

  def initialize(context, record)
    @kind = record.class.name
    @record_id = record.id
    states = context[:lazy_cover_games] ||= {}
    @state = states[@kind] ||= { pending: Set.new, loaded: {} }
    @state[:pending] << @record_id unless @state[:loaded].key?(@record_id)
  end

  # @return [Array<Game>]
  def value
    load_pending unless @state[:loaded].key?(@record_id)
    @state[:loaded].fetch(@record_id)
  end

  private

  def load_pending
    record_ids = @state[:pending].to_a
    rows = ActiveRecord::Base.connection.select_rows(ranking_sql(record_ids))
    games = Game.where(id: rows.map(&:second)).with_attached_cover.index_by(&:id)

    record_ids.each { |id| @state[:loaded][id] = [] }
    rows.each { |record_id, game_id| @state[:loaded][record_id] << games.fetch(game_id) }
    @state[:pending].clear
  end

  # The top games per record. Owners are counted with a correlated subquery,
  # like `ResourceGameSort`'s most_owners order, so only games in these
  # records are counted.
  def ranking_sql(record_ids)
    source = SOURCES.fetch(@kind)
    sql = <<~SQL.squish
      SELECT ranked.record_id, ranked.game_id
      FROM (
        SELECT #{source[:key]} AS record_id, games.id AS game_id,
          ROW_NUMBER() OVER (
            PARTITION BY #{source[:key]}
            ORDER BY (SELECT COUNT(*) FROM game_purchases WHERE game_purchases.game_id = games.id) DESC, games.id ASC
          ) AS position
        FROM #{source[:from]}
        JOIN active_storage_attachments cover
          ON cover.record_type = 'Game' AND cover.record_id = games.id AND cover.name = 'cover'
        WHERE #{source[:key]} IN (:record_ids)
      ) ranked
      WHERE ranked.position <= :limit
      ORDER BY ranked.record_id, ranked.position
    SQL
    ActiveRecord::Base.sanitize_sql([sql, { record_ids: record_ids, limit: LIMIT }])
  end
end
