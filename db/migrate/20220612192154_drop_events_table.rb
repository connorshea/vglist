# typed: true
class DropEventsTable < ActiveRecord::Migration[6.1]
  CONSTRAINT = <<~SQL.squish
    (event_category IN (0, 1) AND eventable_type = 'GamePurchase')
    OR (event_category = 2 AND eventable_type = 'FavoriteGame')
    OR (event_category = 3 AND eventable_type = 'User')
    OR (event_category = 4 AND eventable_type = 'Relationship')
  SQL

  def change
    remove_check_constraint :events, CONSTRAINT, name: "event_category_type_check"

    drop_table :events, id: :uuid do |t|
      t.references :user, null: false
      t.bigint :eventable_id, null: false
      t.integer :event_category, null: false
      t.jsonb :differences
      t.string :eventable_type, null: false

      t.timestamps

      t.index :eventable_id
      t.index [:eventable_id, :eventable_type, :user_id], name: :index_events_on_id_type_and_user_id
    end
  end
end
