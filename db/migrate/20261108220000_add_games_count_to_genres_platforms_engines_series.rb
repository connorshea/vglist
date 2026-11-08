# frozen_string_literal: true

# Counter caches for the number of games in each genre, platform, engine and
# series. Sorting those lists by "Most games" (and showing each row's count)
# counted every record's games on each request, reading the whole join table
# just to return one page.
#
# Companies keep counting in SQL: a company's games come from two join tables
# (developed and published), and a game they both developed and published
# counts once.
class AddGamesCountToGenresPlatformsEnginesSeries < ActiveRecord::Migration[7.2]
  # Each table and the SQL that counts its games, keyed by the record's ID.
  COUNTS = {
    genres: 'SELECT genre_id AS id, count(*) AS count FROM game_genres GROUP BY genre_id',
    platforms: 'SELECT platform_id AS id, count(*) AS count FROM game_platforms GROUP BY platform_id',
    engines: 'SELECT engine_id AS id, count(*) AS count FROM game_engines GROUP BY engine_id',
    series: 'SELECT series_id AS id, count(*) AS count FROM games WHERE series_id IS NOT NULL GROUP BY series_id'
  }.freeze

  def up
    COUNTS.each do |table, counts_sql|
      add_column table, :games_count, :integer, default: 0, null: false
      execute <<~SQL.squish
        UPDATE #{table} SET games_count = counts.count
        FROM (#{counts_sql}) counts
        WHERE #{table}.id = counts.id
      SQL
    end
  end

  def down
    COUNTS.each_key { |table| remove_column table, :games_count }
  end
end
