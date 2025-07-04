class DropMobyGamesIdColumn < ActiveRecord::Migration[7.0]
  def change
    remove_index :games, :mobygames_id, unique: true
    remove_column :games, :mobygames_id, :text
  end
end
