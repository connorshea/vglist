module Resolvers
  module GenreResolvers
    class GenreResolver < Resolvers::BaseResolver
      type Types::GenreType, null: true

      description "Find a genre by ID."

      argument :id, ID, required: true

      def resolve(id:)
        Genre.find(id)
      end
    end
  end
end
