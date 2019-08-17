# typed: true
class AddBeforeAfterValueColumnsToGamePurchaseEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :game_purchase_events, :before_value, :text, null: true
    add_column :game_purchase_events, :after_value, :text, null: true
  end
end
