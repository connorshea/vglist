class RemovePurchaseDateFromGamePurchases < ActiveRecord::Migration[5.2]
  def change
    remove_column :game_purchases, :purchase_date, :date
  end
end
