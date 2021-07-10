# typed: true
class AddIndexForGamePurchaseRatings < ActiveRecord::Migration[6.1]
  def change
    add_index :game_purchases,
              [:rating, :game_id],
              where: 'rating IS NOT NULL',
              name: :index_game_purchases_on_extant_rating_and_game_id
  end
end
