# frozen_string_literal: true

# A counter cache of each game's library entries, so the "Popular" sort
# (Game.most_owners) can read the order from an index instead of joining and
# grouping every game_purchases row on every request. It's filled in by the
# next migration, which runs outside a transaction.
#
# Adding a column with a constant default is a catalog-only change, but it
# still needs a brief ACCESS EXCLUSIVE lock on games. If a long query is
# holding games, give up quickly rather than queue every other request behind
# this one; the deploy can be retried.
class AddGamePurchasesCountToGames < ActiveRecord::Migration[7.2]
  def up
    execute "SET LOCAL lock_timeout = '5s'"
    add_column :games, :game_purchases_count, :integer, null: false, default: 0
  end

  def down
    remove_column :games, :game_purchases_count
  end
end
