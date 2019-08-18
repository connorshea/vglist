# typed: true
class AddBeforeAfterValueColumnsToGamePurchaseEvents < ActiveRecord::Migration[6.0]
  def change
    change_table :game_purchase_events, bulk: true do |t|
      t.text :before_value, null: true
      t.text :after_value, null: true
    end
  end
end
