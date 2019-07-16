# typed: true
class AddScoreToGamePurchase < ActiveRecord::Migration[5.2]
  def change
    add_column :game_purchases, :score, :integer
  end
end
