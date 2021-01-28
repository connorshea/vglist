# typed: strict
module Resolvers
  module SeriesResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::SeriesType.connection_type, null: true

      description "Find a series by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      sig { params(query: String).returns(Series::RelationType) }
      def resolve(query:)
        Series.search(query)
      end
    end
  end
end
