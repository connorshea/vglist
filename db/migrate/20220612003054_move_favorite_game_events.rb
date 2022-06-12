# typed: true
# Move the events records from the `events` table to the new separate tables
# per-eventable type.
class MoveFavoriteGameEvents < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    return if ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM events WHERE eventable_type = 'FavoriteGame'").rows.flatten.first.zero?

    Events::FavoriteGameEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'FavoriteGame';").to_a
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::FavoriteGameEvent.destroy_all
  end
end
