# frozen_string_literal: true

module Resolvers
  module GameResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "Find a game by searching based on its name."

      search_query_argument "Name to search by."

      # Preload based on the fields the client actually selected. See
      # `GamePreloads`.
      extras [:lookahead]

      def resolve(query:, lookahead:)
        GamePreloads.apply(Game.search(query), lookahead)
      end
    end
  end
end
