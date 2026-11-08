# frozen_string_literal: true

# Every activity feed reads the new_events view, a UNION ALL over these four
# tables ordered by created_at desc. With no index on created_at, Postgres has
# to read and sort every event to return the first page.
#
# - (created_at) lets the global feed walk each table backwards and combine
#   them with a Merge Append, stopping once it has a page of events.
# - (user_id, created_at) does the same for a single user's profile activity
#   and the following feed.
#
# Built concurrently so events can still be written while the indexes build.
# if_not_exists makes the migration safe to re-run if a deploy is cancelled
# partway through (a cancelled concurrent build can leave an INVALID index
# behind, which needs dropping by hand before re-running).
class AddCreatedAtIndexesToEvents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  TABLES = %i[
    events_game_purchase_events
    events_favorite_game_events
    events_user_events
    events_relationship_events
  ].freeze

  def change
    TABLES.each do |table|
      add_index table, :created_at, algorithm: :concurrently, if_not_exists: true
      add_index table, [:user_id, :created_at], algorithm: :concurrently, if_not_exists: true
    end
  end
end
