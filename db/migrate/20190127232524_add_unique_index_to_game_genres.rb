# typed: true
class AddUniqueIndexToGameGenres < ActiveRecord::Migration[5.2]
  def change
    add_index :game_genres, [:game_id, :genre_id], unique: true
  end
end
