# frozen_string_literal: true

module Types::Enums
  class GamePurchaseSortType < Types::BaseEnum
    description "Options for sorting the games in a user's library."

    value "GAME_NAME", value: 'by_game_name', description: "Sorted alphabetically by the name of the game."
    value "HIGHEST_RATING", value: 'highest_rating', description: "Sorted with the user's highest-rated games first. Games the user hasn't rated are last."
    value "MOST_HOURS_PLAYED", value: 'most_hours_played', description: "Sorted with the games the user has played the most hours of first. Games with no hours logged are last."
  end
end
