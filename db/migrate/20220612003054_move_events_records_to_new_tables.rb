# typed: true
# Move the events records from the `events` table to the new separate tables
# per-eventable type.
class MoveEventsRecordsToNewTables < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    favorite_game_events = ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'FavoriteGame';").to_a
    Events::FavoriteGameEvent.insert_all(favorite_game_events) unless favorite_game_events.empty?

    relationship_events = ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'Relationship';").to_a
    Events::RelationshipEvent.insert_all(relationship_events) unless relationship_events.empty?

    user_events = ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'User';").to_a
    Events::UserEvent.insert_all(user_events) unless user_events.empty?

    game_purchase_events = ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category, differences FROM events WHERE eventable_type = 'GamePurchase';").to_a
    Events::GamePurchaseEvent.insert_all(game_purchase_events) unless game_purchase_events.empty?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::FavoriteGameEvent.destroy_all
    Events::RelationshipEvent.destroy_all
    Events::UserEvent.destroy_all
    Events::GamePurchaseEvent.destroy_all
  end
end
