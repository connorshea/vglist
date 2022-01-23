# typed: strict
module Resolvers
  module EngineResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::EngineType.connection_type, null: true

      description "List all game engines."

      sig { returns(Engine::PrivateRelation) }
      def resolve
        Engine.all
      end
    end
  end
end
