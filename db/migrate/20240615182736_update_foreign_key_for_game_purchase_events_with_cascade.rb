# typed: true
class UpdateForeignKeyForGamePurchaseEventsWithCascade < ActiveRecord::Migration[7.1]
  def change
    # Remove the existing foreign key
    remove_foreign_key :events_game_purchase_events, :game_purchases, column: :eventable_id

    # Add the new foreign key with ON DELETE CASCADE
    add_foreign_key :events_game_purchase_events, :game_purchases, column: :eventable_id, on_delete: :cascade
  end
end
