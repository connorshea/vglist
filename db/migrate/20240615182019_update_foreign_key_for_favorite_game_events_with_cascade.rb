# typed: true
class UpdateForeignKeyForFavoriteGameEventsWithCascade < ActiveRecord::Migration[7.1]
  def change
     # Remove the existing foreign key
     remove_foreign_key :events_favorite_game_events, :favorite_games

     # Add the new foreign key with ON DELETE CASCADE
     add_foreign_key :events_favorite_game_events, :favorite_games, column: :eventable_id, on_delete: :cascade
  end
end
