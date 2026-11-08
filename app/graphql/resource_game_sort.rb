# frozen_string_literal: true

# Orders the games on a resource page (a company's developed or published
# games, or a platform's, engine's, genre's or series' games).
#
# Unlike the `Game` sort scopes used by the games index, none of these drop
# games from the list: `Game.recently_released` hides unreleased games and
# `Game.highest_avg_rating` hides games with fewer than five ratings, which
# would make a resource's game count disagree with the games it shows. Every
# order ends on `games.id` so that pagination is stable across ties.
module ResourceGameSort
  ORDERS = {
    newest_release: 'games.release_date DESC NULLS LAST, games.id DESC',
    # The counter cache that Game.most_owners also sorts on, rather than
    # counting each game's library entries per query.
    most_owners: 'games.game_purchases_count DESC, games.id DESC',
    highest_rated: 'games.avg_rating DESC NULLS LAST, games.id DESC',
    name: 'games.name ASC, games.id ASC'
  }.freeze

  # Join tables that carry a copy of each game's release date (kept in sync by
  # database triggers), indexed by the resource and that date. Sorting on the
  # join table's copy lets Postgres read a page of a platform's games
  # newest-first straight from the index, rather than fetching and sorting
  # every game on the platform. `game_id` is the same as `games.id`, so the
  # order is the same as `ORDERS[:newest_release]`.
  RELEASE_DATE_JOIN_TABLES = ['game_platforms', 'game_genres'].freeze

  module_function

  # @param relation [ActiveRecord::Relation] A relation of games.
  # @param sort_by [Symbol, nil] A `ResourceGameSortType` value. Without one,
  #   the games are ordered by ID so that pagination is still stable.
  # @param join_table [String, nil] The join table the relation goes through,
  #   if it's one of `RELEASE_DATE_JOIN_TABLES`.
  # @return [ActiveRecord::Relation]
  def apply(relation, sort_by, join_table: nil)
    return relation.order('games.id ASC') if sort_by.nil?

    relation.order(Arel.sql(order_for(sort_by, join_table)))
  end

  # @param sort_by [Symbol]
  # @param join_table [String, nil]
  # @return [String]
  def order_for(sort_by, join_table)
    return ORDERS.fetch(sort_by) unless sort_by == :newest_release && join_table

    raise ArgumentError, "#{join_table} has no release_date column" unless RELEASE_DATE_JOIN_TABLES.include?(join_table)

    "#{join_table}.release_date DESC NULLS LAST, #{join_table}.game_id DESC"
  end
end
