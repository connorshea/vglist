class RenameFavoritesToFavoriteGames < ActiveRecord::Migration[5.2]
  def change
    rename_table :favorites, :favorite_games
  end
end
