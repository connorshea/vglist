# typed: strict
module Resolvers
  module GameResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "List all games."

      argument :sort_by, Types::GameSortType, required: false, description: "The order to sort the games in, if any."

      sig { params(sort_by: T.nilable(String)).returns(Game::RelationType) }
      def resolve(sort_by: nil)
        games = Game.all
        sort_by.nil? ? games.order(:id) : games.public_send(sort_by.to_sym)
      end
    end
  end
end
