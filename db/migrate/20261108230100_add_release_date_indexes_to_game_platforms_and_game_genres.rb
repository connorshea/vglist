# frozen_string_literal: true

# Lets the "Newest release" sort on a platform's or genre's games read the
# first page straight from the join table, newest-first, and stop after a
# page, however many games the platform or genre has. Matches
# ResourceGameSort's newest_release order on the join table.
#
# Built concurrently so that game edits keep working while they build.
class AddReleaseDateIndexesToGamePlatformsAndGameGenres < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :game_platforms, [:platform_id, :release_date, :game_id],
              order: { release_date: 'DESC NULLS LAST', game_id: :desc },
              name: 'index_game_platforms_on_platform_id_and_release_date',
              algorithm: :concurrently
    add_index :game_genres, [:genre_id, :release_date, :game_id],
              order: { release_date: 'DESC NULLS LAST', game_id: :desc },
              name: 'index_game_genres_on_genre_id_and_release_date',
              algorithm: :concurrently
  end
end
