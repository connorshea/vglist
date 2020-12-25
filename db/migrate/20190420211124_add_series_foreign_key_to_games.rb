class AddSeriesForeignKeyToGames < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :games, :series, column: :series_id, on_delete: :nullify
  end
end
