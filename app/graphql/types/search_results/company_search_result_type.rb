# typed: true
module Types
  module SearchResults
    class CompanySearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A company search result."
    end
  end
end
