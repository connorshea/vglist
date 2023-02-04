# typed: strict
module Resolvers
  module GenreResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GenreType.connection_type, null: true

      description "List all genres."

      sig { returns(T.untyped) }
      def resolve
        Genre.all
      end
    end
  end
end
