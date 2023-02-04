# typed: false
class MoveGamePurchaseEvents < ActiveRecord::Migration[6.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    return if ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM events WHERE eventable_type = 'GamePurchase'").rows.flatten.first.zero?

    # Move records over in batches of 1000 at a time to avoid creating too much pressure on the database all at once.
    Event.where(eventable_type: 'GamePurchase').find_in_batches(batch_size: 1000) do |batch|
      Events::GamePurchaseEvent.insert_all(
        batch.as_json(only: [:id, :user_id, :eventable_id, :created_at, :updated_at, :event_category, :differences])
      )
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    Events::GamePurchaseEvent.destroy_all
  end
end
