# typed: true
module Resolvers
  module GameResolvers
    class GameResolver < Resolvers::BaseResolver
      type Types::GameType, null: true

      description "Find a game by ID or GiantBomb ID. May only use one of the filters at a time."

      argument :id, ID, required: false, description: "Find a game by its unique ID."
      argument :giantbomb_id, String, required: false, description: "Find a game by its GiantBomb ID, e.g. `'3030-23708'`."

      # Use validator to validate that one of the arguments is being used.
      validates required: {
        one_of: [:id, :giantbomb_id],
        message: 'Cannot provide more than one argument to game at a time.'
      }

      sig do
        params(
          id: T.nilable(T.any(String, Integer)),
          giantbomb_id: T.nilable(String)
        ).returns(T.nilable(Game))
      end
      def resolve(id: nil, giantbomb_id: nil)
        if !id.nil?
          Game.find(id)
        elsif !giantbomb_id.nil?
          Game.find_by(giantbomb_id: giantbomb_id)
        end
      end
    end
  end
end
