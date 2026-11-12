# frozen_string_literal: true

# Game validates that pcgamingwiki_id is unique, but unlike the other external
# IDs it had no index, so every game save (including the rating update after
# each library change) ran a sequential scan over games to check it. In
# production that took 250-420ms per save.
#
# Not a unique index: the uniqueness validation is what has kept the data in
# check so far, and a unique index would fail to build if any duplicates have
# slipped in. Built concurrently so game edits keep working while it builds.
class AddPcgamingwikiIdIndexToGames < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :games, :pcgamingwiki_id, algorithm: :concurrently
  end
end
