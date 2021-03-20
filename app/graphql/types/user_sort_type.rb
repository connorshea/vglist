# typed: strict
module Types
  class UserSortType < Types::BaseEnum
    description "Options for sorting users."

    value 'MOST_GAMES', value: 'most_games', description: 'Sorted by the number of games in the given user\'s library.'
    value 'MOST_FOLLOWERS', value: 'most_followers', description: 'Sorted by the number of users following the given user.'
  end
end
