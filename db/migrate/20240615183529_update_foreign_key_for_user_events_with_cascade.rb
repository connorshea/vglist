# typed: true
class UpdateForeignKeyForUserEventsWithCascade < ActiveRecord::Migration[7.1]
  def change
    # Remove the existing foreign key
    remove_foreign_key :events_user_events, :users, column: :eventable_id

    # Add the new foreign key with ON DELETE CASCADE
    add_foreign_key :events_user_events, :users, column: :eventable_id, on_delete: :cascade
  end
end
