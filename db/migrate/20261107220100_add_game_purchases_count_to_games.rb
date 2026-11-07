# frozen_string_literal: true

# A counter cache of each game's library entries, so the "Popular" sort
# (Game.most_owners) can read the order from an index instead of joining and
# grouping every game_purchases row on every request.
class AddGamePurchasesCountToGames < ActiveRecord::Migration[7.2]
  def up
    add_column :games, :game_purchases_count, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE games
      SET game_purchases_count = counts.count
      FROM (SELECT game_id, COUNT(*) AS count FROM game_purchases GROUP BY game_id) counts
      WHERE counts.game_id = games.id
    SQL

    add_index :games, [:game_purchases_count, :id]
  end

  def down
    remove_column :games, :game_purchases_count
  end
end
