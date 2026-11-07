# frozen_string_literal: true

# Scopes for the index pages of resources that group games (series, genres,
# platforms, companies, engines): a game count loaded alongside each record,
# the three sort orders those pages offer, and a name filter.
#
# The count is a correlated subquery rather than a join + GROUP BY, so the
# relation stays ungrouped: it can still be filtered, `totalCount` is a plain
# count, and each row carries its own number.
module GameCountScopes
  extend ActiveSupport::Concern

  class_methods do
    # @param games_count_sql [String] A correlated subquery that counts one
    #   record's games, e.g. `(SELECT COUNT(*) FROM games WHERE games.series_id = series.id)`.
    def game_count_scopes(games_count_sql)
      table = table_name

      # Loads each record's game count as `index_games_count`, for lists that
      # show it on every row.
      scope :with_games_count, -> { select("#{table}.*", "#{games_count_sql} AS index_games_count") }

      # Each order ends on the ID so that pagination is stable across ties.
      scope :most_games, -> { order(Arel.sql("#{games_count_sql} DESC, #{table}.id ASC")) }
      scope :alphabetical, -> { order(Arel.sql("LOWER(#{table}.name) ASC, #{table}.id ASC")) }
      scope :recently_added, -> { order(created_at: :desc, id: :desc) }

      # Case-insensitive substring match on the name, for filtering a list.
      scope :name_contains, ->(text) { where("#{table}.name ILIKE ?", "%#{sanitize_sql_like(text)}%") }
    end
  end
end
