# frozen_string_literal: true

# Lets Game.highest_avg_rating read its games in order straight from an
# index. Only games with enough ratings to be listed are indexed, which keeps
# it small.
#
# Built concurrently so that writes to games (including the avg_rating update
# after every library edit) keep working while it builds.
class AddHighestAvgRatingIndexToGames < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :games, [:avg_rating, :id],
              where: 'ratings_count >= 5 AND avg_rating IS NOT NULL',
              name: 'index_games_on_avg_rating_and_id_when_rated',
              algorithm: :concurrently
  end
end
