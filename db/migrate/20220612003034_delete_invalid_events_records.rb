# typed: false
class DeleteInvalidEventsRecords < ActiveRecord::Migration[6.1]
  # Delete invalid events that are invalid due to the corresponding GamePurchase
  # not existing anymore. This is the only a problem for GamePurchase-related
  # events, based on our production data.
  def up
    invalid_event_ids = ActiveRecord::Base.connection.exec_query(
      <<~SQL.squish
        SELECT events.id FROM events
        LEFT JOIN game_purchases ON events.eventable_id = game_purchases.id
        WHERE eventable_type = 'GamePurchase'
        AND game_purchases.id IS NULL;
      SQL
    ).to_a.map { |hash| hash['id'] }

    return if invalid_event_ids.empty?

    Event.where(id: invalid_event_ids).destroy_all
  end

  def down
    # no-op
  end
end
