# typed: true
class MoveUserEvents < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    Events::UserEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'User';").to_a
    ) unless ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM events WHERE eventable_type = 'User'").rows.flatten.first.zero?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::UserEvent.destroy_all
  end
end
