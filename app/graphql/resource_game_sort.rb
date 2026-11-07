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

  module_function

  # @param relation [ActiveRecord::Relation] A relation of games.
  # @param sort_by [Symbol, nil] A `ResourceGameSortType` value. Without one,
  #   the games are ordered by ID so that pagination is still stable.
  # @return [ActiveRecord::Relation]
  def apply(relation, sort_by)
    return relation.order('games.id ASC') if sort_by.nil?

    relation.order(Arel.sql(ORDERS.fetch(sort_by)))
  end
end
