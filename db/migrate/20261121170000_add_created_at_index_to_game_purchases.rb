# frozen_string_literal: true

# The home page's "Recently added to libraries" shelf walks library entries
# newest first (see RecentLibraryAdditions). Without an index on created_at
# that's a sort of the whole game_purchases table every time the list is
# recomputed. The id breaks ties between entries added in the same Steam
# import, so the walk can resume from the last row it read.
#
# Built concurrently so library changes keep working while it builds.
class AddCreatedAtIndexToGamePurchases < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :game_purchases, [:created_at, :id], algorithm: :concurrently
  end
end
