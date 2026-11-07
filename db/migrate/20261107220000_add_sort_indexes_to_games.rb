# frozen_string_literal: true

# The "New releases" and "Recently added" shelves on the home page (and the
# matching games index sorts) order every game by these columns. Without an
# index, Postgres reads and sorts the whole games table to find the first few.
#
# Built concurrently so that writes to games (including the avg_rating update
# after every library edit) keep working while the indexes build.
class AddSortIndexesToGames < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :games, [:release_date, :id], algorithm: :concurrently
    add_index :games, [:created_at, :id], algorithm: :concurrently
  end
end
