# typed: true
class AddUniqueIndexOnGamePurchasesGameAndUser < ActiveRecord::Migration[6.0]
  def change
    add_index :game_purchases, [:game_id, :user_id], unique: true
  end
end
