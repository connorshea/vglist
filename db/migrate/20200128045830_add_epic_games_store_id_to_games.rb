# typed: true
class AddEpicGamesStoreIdToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :epic_games_store_id, :text, null: true
    add_index :games, :epic_games_store_id, unique: true
  end
end
