# frozen_string_literal: true

module Resolvers
  module GenreResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::GenreType.connection_type, null: true

      description "Find a genre by searching based on its name."

      search_query_argument "Name to search by."

      def resolve(query:)
        Genre.search(query)
      end
    end
  end
end
