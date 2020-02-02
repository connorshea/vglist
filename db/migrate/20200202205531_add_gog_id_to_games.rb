class AddGogIdToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :gog_id, :text, null: true
  end
end
