# typed: true
class AddEventTypeToGamePurchaseEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :game_purchase_events, :event_type, :integer, null: false
  end
end
