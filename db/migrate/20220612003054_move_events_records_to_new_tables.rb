# typed: true
# Move the events records from the `events` table to the new separate tables
# per-eventable type.
class MoveEventsRecordsToNewTables < ActiveRecord::Migration[6.1]
  def up
    columns = [:user_id, :eventable_id, :created_at, :updated_at, :event_category]

    # rubocop:disable Rails/SkipsModelValidations
    Events::FavoriteGameEvent.insert_all(
      Event.where(eventable_type: 'FavoriteGame').as_json(only: columns)
    )

    Events::RelationshipEvent.insert_all(
      Event.where(eventable_type: 'Relationship').as_json(only: columns)
    )

    Events::UserEvent.insert_all(
      Event.where(eventable_type: 'User').as_json(only: columns)
    )

    Events::GamePurchaseEvent.insert_all(
      Event.where(eventable_type: 'GamePurchase').as_json(only: columns.concat([:differences]))
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::FavoriteGameEvent.destroy_all
    Events::RelationshipEvent.destroy_all
    Events::UserEvent.destroy_all
    Events::GamePurchaseEvent.destroy_all
  end
end
