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
    # A correlated subquery rather than a join + GROUP BY, so the relation
    # stays ungrouped and `totalCount` is still a plain count.
    most_owners: '(SELECT COUNT(*) FROM game_purchases WHERE game_purchases.game_id = games.id) DESC, games.id DESC',
    highest_rated: 'games.avg_rating DESC NULLS LAST, games.id DESC',
    name: 'games.name ASC, games.id ASC'
  }.freeze

  module_function

  # @param relation [ActiveRecord::Relation] A relation of games.
  # @param sort_by [Symbol, nil] A `ResourceGameSortType` value.
  # @return [ActiveRecord::Relation]
  def apply(relation, sort_by)
    return relation if sort_by.nil?

    relation.order(Arel.sql(ORDERS.fetch(sort_by)))
  end
end
