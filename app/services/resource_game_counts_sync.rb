# frozen_string_literal: true

# Recalculates the `games_count` counter caches on genres, platforms, engines
# and series and fixes any that have drifted.
#
# The join models' (and Game's belongs_to :series) counter caches keep them
# right for normal edits, but they can drift: games edited by the old code
# while a deploy's migrations run, or rows changed with raw SQL. This runs
# from the daily `vglist:update:stats` job.
#
# These tables are small (thousands of rows), so each is fixed with a single
# UPDATE that only writes the rows that are wrong.
class ResourceGameCountsSync
  # Each table and the SQL that counts its games, keyed by the record's ID.
  COUNTS = {
    genres: 'SELECT genre_id AS id, COUNT(*) AS count FROM game_genres GROUP BY genre_id',
    platforms: 'SELECT platform_id AS id, COUNT(*) AS count FROM game_platforms GROUP BY platform_id',
    engines: 'SELECT engine_id AS id, COUNT(*) AS count FROM game_engines GROUP BY engine_id',
    series: 'SELECT series_id AS id, COUNT(*) AS count FROM games WHERE series_id IS NOT NULL GROUP BY series_id'
  }.freeze

  # @return [Integer] How many records were corrected, across all tables.
  def self.call
    connection = ActiveRecord::Base.connection
    COUNTS.sum do |table, counts_sql|
      connection.exec_update(<<~SQL.squish, 'ResourceGameCountsSync')
        UPDATE #{table}
        SET games_count = COALESCE(counts.count, 0)
        FROM #{table} AS records
        LEFT JOIN (#{counts_sql}) counts ON counts.id = records.id
        WHERE #{table}.id = records.id
          AND #{table}.games_count IS DISTINCT FROM COALESCE(counts.count, 0)
      SQL
    end
  end
end
