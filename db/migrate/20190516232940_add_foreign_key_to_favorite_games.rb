# typed: true
class AddForeignKeyToFavoriteGames < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :favorite_games, :games, column: :game_id, on_delete: :cascade
  end
end
