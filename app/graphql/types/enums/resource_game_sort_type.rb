# frozen_string_literal: true

module Types::Enums
  class ResourceGameSortType < Types::BaseEnum
    description "Options for sorting the games on a company, platform, engine, genre or series."

    value "NEWEST_RELEASE", value: :newest_release, description: 'Sorted with the most recently released games first. Games without a release date come last.'
    value "MOST_OWNERS", value: :most_owners, description: 'Sorted by the games that are in the most users\' libraries.'
    value "HIGHEST_RATED", value: :highest_rated, description: 'Sorted by the games with the highest average rating. Games without a rating come last.'
    value "NAME", value: :name, description: 'Sorted alphabetically by name.'
  end
end
