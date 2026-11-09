# frozen_string_literal: true

# The (platform_id, release_date, game_id) and (genre_id, release_date,
# game_id) indexes from the previous migration start with the same column, so
# they serve every lookup these did. Dropping them keeps the join tables at
# the same number of indexes to maintain on each write.
class RemoveRedundantResourceIdIndexesFromGamePlatformsAndGameGenres < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    remove_index :game_platforms, :platform_id, name: 'index_game_platforms_on_platform_id', algorithm: :concurrently
    remove_index :game_genres, :genre_id, name: 'index_game_genres_on_genre_id', algorithm: :concurrently
  end
end
