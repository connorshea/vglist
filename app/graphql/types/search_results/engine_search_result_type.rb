# typed: strict
module Types
  module SearchResults
    class EngineSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "An engine search result."
    end
  end
end
