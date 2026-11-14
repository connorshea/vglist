# frozen_string_literal: true

# Scopes for the index pages of resources that group games (series, genres,
# platforms, companies, engines): the three sort orders those pages offer, and
# a name filter.
#
# Each model stores its game count in a `games_count` column: a counter cache
# for genres, platforms, engines and series, and one kept up to date by
# CompanyGamesCount for companies, since their games come from two join
# tables and a game can be in both.
module GameCountScopes
  extend ActiveSupport::Concern

  class_methods do
    # @param games_count_sql [String] SQL for one record's game count, its
    #   games_count column (e.g. `genres.games_count`).
    def game_count_scopes(games_count_sql)
      table = table_name

      # Each order ends on the ID so that pagination is stable across ties.
      scope :most_games, -> { order(Arel.sql("#{games_count_sql} DESC, #{table}.id ASC")) }
      scope :alphabetical, -> { order(Arel.sql("LOWER(#{table}.name) ASC, #{table}.id ASC")) }
      scope :recently_added, -> { order(created_at: :desc, id: :desc) }

      # Case-insensitive substring match on the name, for filtering a list.
      scope :name_contains, ->(text) { where("#{table}.name ILIKE ?", "%#{sanitize_sql_like(text)}%") }
    end
  end
end
