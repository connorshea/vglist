# typed: false
class CreateEventsGamePurchaseEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events_game_purchase_events, id: :uuid do |t|
      t.references :user, null: false
      t.references :eventable, foreign_key: { to_table: :game_purchases }, null: false
      t.jsonb :differences
      t.integer :event_category, null: false

      t.timestamps
    end
  end
end
