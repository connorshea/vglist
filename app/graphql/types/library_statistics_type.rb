# frozen_string_literal: true

module Types
  class LibraryStatisticsType < Types::BaseObject
    description "Aggregate statistics for the games in a user's library. These are calculated across the whole library, so they don't depend on how many game purchases the client has paged through."

    field :games_count, Integer, null: false, description: "The total number of games in the library."
    field :total_hours_played, Float, null: false, description: "The total number of hours the user has played across every game in their library."
    field :completed_count, Integer, null: false, description: "The number of games in the library that are completed or 100% completed."
    field :completion_percentage, Integer, null: false, description: "The percentage of the games in the library that are completed or 100% completed, rounded to the nearest whole number. `0` if the library is empty."
    field :average_rating, Float, null: true, description: "The average of the user's ratings, out of 100, rounded to one decimal place. `null` if the user hasn't rated any of the games in their library."
    field :status_counts, [Types::LibraryStatusCountType], null: false, description: "The number of games in the library for each completion status. Statuses that no game in the library has are omitted, as are games with no completion status, so these counts can add up to less than `gamesCount`."
  end
end
