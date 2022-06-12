# typed: true
class MoveGamePurchaseEvents < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    Events::GamePurchaseEvent.insert_all(
      ActiveRecord::Base.connection.exec_query("SELECT id, user_id, eventable_id, created_at, updated_at, event_category, differences FROM events WHERE eventable_type = 'GamePurchase';").to_a
    ) unless ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM events WHERE eventable_type = 'GamePurchase'").rows.flatten.first.zero?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::GamePurchaseEvent.destroy_all
  end
end
