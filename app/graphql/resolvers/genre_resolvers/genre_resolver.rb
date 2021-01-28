# typed: strict
module Resolvers
  module GenreResolvers
    class GenreResolver < Resolvers::BaseResolver
      type Types::GenreType, null: true

      description "Find a genre by ID."

      argument :id, ID, required: true

      sig { params(id: T.any(String, Integer)).returns(Genre) }
      def resolve(id:)
        Genre.find(id)
      end
    end
  end
end
