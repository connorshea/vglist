# frozen_string_literal: true

module Resolvers
  module SeriesResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::SeriesType.connection_type, null: true

      description "Find a series by searching based on its name."

      search_query_argument "Name to search by."

      def resolve(query:)
        Series.search(query)
      end
    end
  end
end
