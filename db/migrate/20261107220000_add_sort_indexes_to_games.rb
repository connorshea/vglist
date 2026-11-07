# frozen_string_literal: true

# The "New releases" and "Recently added" shelves on the home page (and the
# matching games index sorts) order every game by these columns. Without an
# index, Postgres reads and sorts the whole games table to find the first few.
class AddSortIndexesToGames < ActiveRecord::Migration[7.2]
  def change
    add_index :games, [:release_date, :id]
    add_index :games, [:created_at, :id]
  end
end
