# typed: true
class AddSteamAppIdsToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :steam_app_id, :integer
    add_index :games, :steam_app_id, unique: true
  end
end
