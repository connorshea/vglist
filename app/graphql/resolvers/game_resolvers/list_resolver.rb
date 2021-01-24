# typed: true
module Resolvers
  module GameResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "List all games."

      sig { returns(Game::RelationType) }
      def resolve
        Game.all
      end
    end
  end
end
