# frozen_string_literal: true

# The number of library entries with a rating, kept next to avg_rating (see
# GamePurchase#update_average_rating). Game.highest_avg_rating only lists
# games with at least five ratings, and without this column it had to join
# and count every game's library entries on each request.
class AddRatingsCountToGames < ActiveRecord::Migration[7.2]
  def up
    add_column :games, :ratings_count, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE games SET ratings_count = rated.count
      FROM (
        SELECT game_id, count(*) AS count FROM game_purchases
        WHERE rating IS NOT NULL GROUP BY game_id
      ) rated
      WHERE games.id = rated.game_id
    SQL
  end

  def down
    remove_column :games, :ratings_count
  end
end
