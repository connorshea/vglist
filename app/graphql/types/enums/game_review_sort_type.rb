# frozen_string_literal: true

module Types::Enums
  class GameReviewSortType < Types::BaseEnum
    description "Options for sorting the reviews of a game."

    value "RECENT", value: 'recent', description: "Sorted with the most recently updated reviews first."
    value "HIGHEST_RATING", value: 'highest_rating', description: "Sorted with the highest-rated reviews first. Reviews without a rating are last."
    value "LOWEST_RATING", value: 'lowest_rating', description: "Sorted with the lowest-rated reviews first. Reviews without a rating are last."
  end
end
