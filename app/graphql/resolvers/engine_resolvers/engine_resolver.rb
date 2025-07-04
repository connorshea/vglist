module Resolvers
  module EngineResolvers
    class EngineResolver < Resolvers::BaseResolver
      type Types::EngineType, null: true

      description "Find a game engine by ID."

      argument :id, ID, required: true

      def resolve(id:)
        Engine.find(id)
      end
    end
  end
end
