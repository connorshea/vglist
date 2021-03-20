# typed: strict
module Types
  module SearchResults
    class GenreSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A genre search result."
    end
  end
end
