# typed: true
class AddReleaseDateToGames < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :release_date, :date, null: true
  end
end
