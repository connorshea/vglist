# frozen_string_literal: true

module Types::Enums
  class LibraryComparisonSortType < Types::BaseEnum
    description "Options for sorting the games two users have in common."

    value "RATING_GAP", value: 'rating_gap', description: "Sorted with the games the two users disagree on most first. Games that either user hasn't rated are last."
    value "GAME_NAME", value: 'game_name', description: "Sorted alphabetically by the name of the game."
    value "USER_A_RATING", value: 'user_a_rating', description: "Sorted with the first user's highest-rated games first. Games they haven't rated are last."
    value "USER_B_RATING", value: 'user_b_rating', description: "Sorted with the second user's highest-rated games first. Games they haven't rated are last."
  end
end
