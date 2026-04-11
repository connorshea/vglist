# frozen_string_literal: true

module Types
  module SearchResults
    class GenreSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A genre search result."
    end
  end
end
