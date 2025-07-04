class AddHoursPlayedToGamePurchases < ActiveRecord::Migration[5.2]
  def change
    add_column :game_purchases, :hours_played, :decimal, precision: 10, scale: 1
  end
end
