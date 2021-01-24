# typed: true
module Resolvers
  module EngineResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::EngineType.connection_type, null: true

      description "Find a game engine by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      sig { params(query: String).returns(Engine::RelationType) }
      def resolve(query:)
        Engine.search(query)
      end
    end
  end
end
