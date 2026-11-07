# frozen_string_literal: true

# Fills in games.game_purchases_count and indexes it for Game.most_owners.
#
# Runs outside a transaction, a range of game ids at a time, so each UPDATE
# only holds row locks on one batch of games for a moment, and builds the
# index concurrently so writes to games keep working.
#
# The SQL is inlined (rather than calling GamePurchasesCountSync) so this
# migration keeps working however that class changes later.
class BackfillGamePurchasesCountOnGames < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  BATCH_SIZE = 5_000

  def up
    max_id = select_value('SELECT MAX(id) FROM games').to_i
    (0..max_id).step(BATCH_SIZE) do |from|
      execute <<~SQL.squish
        UPDATE games
        SET game_purchases_count = counts.count
        FROM (
          SELECT game_id, COUNT(*) AS count FROM game_purchases
          WHERE game_id >= #{from} AND game_id < #{from + BATCH_SIZE}
          GROUP BY game_id
        ) counts
        WHERE counts.game_id = games.id
          AND games.game_purchases_count IS DISTINCT FROM counts.count
      SQL
    end

    add_index :games, [:game_purchases_count, :id], algorithm: :concurrently
  end

  def down
    remove_index :games, [:game_purchases_count, :id], algorithm: :concurrently
  end
end
