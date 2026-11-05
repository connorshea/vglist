# frozen_string_literal: true

module Types::Enums
  class ResourceSortType < Types::BaseEnum
    description "Options for sorting resources that games belong to, like genres and platforms."

    value 'MOST_GAMES', value: 'most_games', description: 'Sorted by the number of games in the given resource, most first.'
  end
end
