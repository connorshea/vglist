# typed: true
# Move the events records from the `events` table to the new separate tables
# per-eventable type.
class MoveEventsRecordsToNewTables < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    Events::FavoriteGameEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'FavoriteGame';").to_a
    )

    Events::RelationshipEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'Relationship';").to_a
    )

    Events::UserEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'User';").to_a
    )

    Events::GamePurchaseEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category, differences FROM events WHERE eventable_type = 'GamePurchase';").to_a
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
