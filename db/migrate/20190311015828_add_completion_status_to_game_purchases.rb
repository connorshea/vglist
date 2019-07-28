# typed: true
class AddCompletionStatusToGamePurchases < ActiveRecord::Migration[5.2]
  def change
    add_column :game_purchases, :completion_status, :integer
  end
end
