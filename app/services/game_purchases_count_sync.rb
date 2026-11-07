# frozen_string_literal: true

# Recounts games.game_purchases_count from game_purchases and fixes any game
# whose counter has drifted.
#
# The counter cache keeps the column right for normal library edits, but it
# can drift: entries added or removed by the old code while a deploy's
# migrations run, a game merge that fails between its update_all and
# reset_counters, or edits made with raw SQL. This runs after deploys and from
# the daily `vglist:update:stats` job.
#
# Works a range of game ids at a time and only writes the games that are
# wrong, so each UPDATE holds row locks on a handful of games for a moment.
class GamePurchasesCountSync
  BATCH_SIZE = 5_000

  # @return [Integer] How many games were corrected.
  def self.call(batch_size: BATCH_SIZE)
    connection = ActiveRecord::Base.connection
    max_id = Game.maximum(:id).to_i
    (0..max_id).step(batch_size).sum do |from|
      connection.exec_update(<<~SQL.squish, 'GamePurchasesCountSync', [from, from + batch_size])
        UPDATE games
        SET game_purchases_count = COALESCE(counts.count, 0)
        FROM games AS batch
        LEFT JOIN (
          SELECT game_id, COUNT(*) AS count FROM game_purchases
          WHERE game_id >= $1 AND game_id < $2
          GROUP BY game_id
        ) counts ON counts.game_id = batch.id
        WHERE games.id = batch.id
          AND batch.id >= $1 AND batch.id < $2
          AND games.game_purchases_count IS DISTINCT FROM COALESCE(counts.count, 0)
      SQL
    end
  end
end
