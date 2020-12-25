class AddUniqueIndexToGamePlatforms < ActiveRecord::Migration[5.2]
  def change
    add_index :game_platforms, [:game_id, :platform_id], unique: true
  end
end
