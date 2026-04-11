# frozen_string_literal: true

module Types
  module SearchResults
    class SeriesSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A series search result."
    end
  end
end
