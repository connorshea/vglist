# typed: true
class AddGiantBombIdsToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :giantbomb_id, :text, null: true
    add_index :games, :giantbomb_id, unique: true
  end
end
