class AddMobyGamesIdToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :mobygames_id, :text
    add_index :games, :mobygames_id, unique: true
  end
end
