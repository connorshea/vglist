# typed: true
class CreateNewEventsView < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      CREATE OR REPLACE VIEW public.new_events AS
      SELECT
        id,
        user_id,
        eventable_id,
        differences,
        event_category,
        created_at,
        updated_at,
        'GamePurchase' AS eventable_type
      FROM events_game_purchase_events
      UNION ALL
      SELECT
        id,
        user_id,
        eventable_id,
        NULL AS differences,
        event_category,
        created_at,
        updated_at,
        'FavoriteGame' AS eventable_type
      FROM events_favorite_game_events
      UNION ALL
      SELECT
        id,
        user_id,
        eventable_id,
        NULL AS differences,
        event_category,
        created_at,
        updated_at,
        'User' AS eventable_type
      FROM events_user_events
      UNION ALL
      SELECT
        id,
        user_id,
        eventable_id,
        NULL AS differences,
        event_category,
        created_at,
        updated_at,
        'Relationship' AS eventable_type
      FROM events_relationship_events;
    SQL
  end

  def down
    execute('DROP VIEW IF EXISTS public.new_events;')
  end
end
