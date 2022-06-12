# typed: true
class MoveRelationshipEvents < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    Events::RelationshipEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category FROM events WHERE eventable_type = 'Relationship';").to_a
    ) unless ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM events WHERE eventable_type = 'Relationship'").rows.flatten.first.zero?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::RelationshipEvent.destroy_all
  end
end
