# typed: true
class RenameGamePurchaseEventsToEvents < ActiveRecord::Migration[6.0]
  def up
    rename_table :game_purchase_events, :events
    rename_column :events, :game_purchase_id, :eventable_id
    add_column :events, :eventable_type, :string
    rename_column :events, :event_type, :event_category
    Event.reset_column_information
    # rubocop:disable Rails/SkipsModelValidations
    Event.update_all(eventable_type: "GamePurchase")
    # rubocop:enable Rails/SkipsModelValidations

    add_index :events, [:eventable_id, :eventable_type, :user_id],
      name: :index_events_on_id_type_and_user_id
  end

  def down
    rename_table :events, :game_purchase_events
    rename_column :events, :eventable_id, :game_purchase_id
    rename_column :events, :event_category, :event_type
    remove_column :events, :eventable_type, :string
    remove_index :events, [:eventable_id, :eventable_type, :user_id],
      name: :index_events_on_id_type_and_user_id
  end
end
