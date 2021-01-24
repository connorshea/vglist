# typed: true
module Resolvers
  module EngineResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::EngineType.connection_type, null: true

      description "List all game engines."

      sig { returns(Engine::RelationType) }
      def resolve
        Engine.all
      end
    end
  end
end
