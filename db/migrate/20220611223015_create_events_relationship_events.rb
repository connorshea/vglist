# typed: true
class CreateEventsRelationshipEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events_relationship_events, id: :uuid do |t|
      t.references :user, null: false
      t.references :eventable, foreign_key: { to_table: :relationships }, null: false
      t.integer :event_category, null: false

      t.timestamps
    end
  end
end
