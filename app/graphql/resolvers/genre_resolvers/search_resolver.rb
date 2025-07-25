module Resolvers
  module GenreResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::GenreType.connection_type, null: true

      description "Find a genre by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      def resolve(query:)
        Genre.search(query)
      end
    end
  end
end
