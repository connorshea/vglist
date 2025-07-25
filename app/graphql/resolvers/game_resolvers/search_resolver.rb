module Resolvers
  module GameResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "Find a game by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      def resolve(query:)
        Game.search(query)
      end
    end
  end
end
