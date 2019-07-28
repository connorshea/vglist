# typed: true
class DropGamesGenresTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :games_genres
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
