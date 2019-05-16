class ConvertFavoriteGamesTableToNewFormat < ActiveRecord::Migration[5.2]
  # Remove indices and favoritable_type column, rename favoritable_id to game_id, add new indices.
  def change
    remove_index :favorite_games, :favoritable_id
    remove_index :favorite_games, :favoritable_type
    remove_column :favorite_games, :favoritable_type, :string

    rename_column :favorite_games, :favoritable_id, :game_id

    add_index :favorite_games, :game_id
    add_index :favorite_games, [:user_id, :game_id], unique: true
  end
end
