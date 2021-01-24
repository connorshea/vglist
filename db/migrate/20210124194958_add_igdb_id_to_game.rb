# typed: true
class AddIgdbIdToGame < ActiveRecord::Migration[6.1]
  def change
    add_column :games, :igdb_id, :text, null: true
  end
end
