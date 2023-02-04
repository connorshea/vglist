# typed: strict
module Types::Enums
  class GameSortType < Types::BaseEnum
    description "Options for sorting games."

    value "NEWEST", value: 'newest', description: 'Sorted with newest game records first.'
    value "OLDEST", value: 'oldest', description: 'Sorted with newest game records last.'
    value "RECENTLY_UPDATED", value: 'recently_updated', description: 'Sorted with most recently updated game records first.'
    value "LEAST_RECENTLY_UPDATED", value: 'least_recently_updated', description: 'Sorted with most recently updated game records last.'
    value "MOST_FAVORITES", value: 'most_favorites', description: 'Sorted by the games that have been favorited the most times.'
    value "MOST_OWNERS", value: 'most_owners', description: 'Sorted by the games that are in the most users\' libraries.'
    value "RECENTLY_RELEASED", value: 'recently_released', description: 'Sorted with the games that were most recently released first.'
    value "HIGHEST_AVG_RATING", value: 'highest_avg_rating', description: 'Sorted by the games that have the highest average rating.'
  end
end
