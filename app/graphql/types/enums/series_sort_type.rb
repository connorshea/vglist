# frozen_string_literal: true

module Types::Enums
  class SeriesSortType < Types::BaseEnum
    description "Options for sorting the list of series."

    value 'MOST_GAMES', value: :most_games, description: 'Sorted by the number of games in the series, most first.'
    value 'NAME', value: :alphabetical, description: 'Sorted alphabetically by name, ignoring case.'
    value 'RECENTLY_ADDED', value: :recently_added, description: 'Sorted with the series most recently added to vglist first.'
  end
end
