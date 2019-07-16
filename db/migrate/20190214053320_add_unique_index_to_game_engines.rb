# typed: true
class AddUniqueIndexToGameEngines < ActiveRecord::Migration[5.2]
  def change
    add_index :game_engines, [:game_id, :engine_id], unique: true
  end
end
