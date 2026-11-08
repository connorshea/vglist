# frozen_string_literal: true

# Recalculates the columns on games that are derived from their library
# entries (game_purchases_count, ratings_count and avg_rating) and fixes any
# game where they've drifted.
#
# Callbacks keep them right for normal library edits, but they can drift:
# entries added or removed by the old code while a deploy's migrations run,
# a game merge that fails between its update_all and recalculating, two
# people rating the same game at once (each callback can read the other's
# uncommitted state as missing), or edits made with raw SQL. This runs from
# the daily `vglist:update:stats` job.
#
# Works a range of game ids at a time and only writes the games that are
# wrong, so each UPDATE holds row locks on a handful of games for a moment.
class GameCountersSync
  BATCH_SIZE = 5_000

  # @return [Integer] How many games were corrected.
  def self.call(batch_size: BATCH_SIZE)
    connection = ActiveRecord::Base.connection
    max_id = Game.maximum(:id).to_i
    (0..max_id).step(batch_size).sum do |from|
      # avg_rating is rounded to one decimal place, like Game#update_ratings.
      connection.exec_update(<<~SQL.squish, 'GameCountersSync', [from, from + batch_size])
        UPDATE games
        SET game_purchases_count = COALESCE(counts.purchases, 0),
            ratings_count = COALESCE(counts.ratings, 0),
            avg_rating = counts.avg_rating
        FROM games AS batch
        LEFT JOIN (
          SELECT game_id,
                 COUNT(*) AS purchases,
                 COUNT(rating) AS ratings,
                 ROUND(AVG(rating), 1)::double precision AS avg_rating
          FROM game_purchases
          WHERE game_id >= $1 AND game_id < $2
          GROUP BY game_id
        ) counts ON counts.game_id = batch.id
        WHERE games.id = batch.id
          AND batch.id >= $1 AND batch.id < $2
          AND (
            games.game_purchases_count IS DISTINCT FROM COALESCE(counts.purchases, 0)
            OR games.ratings_count IS DISTINCT FROM COALESCE(counts.ratings, 0)
            OR games.avg_rating IS DISTINCT FROM counts.avg_rating
          )
      SQL
    end
  end
end
