class AddMobyGamesIdNumericToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :mobygames_id, :bigint
    add_index :games, :mobygames_id, unique: true
  end
end
