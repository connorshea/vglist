# typed: strict
module Resolvers
  module PlatformResolvers
    class PlatformResolver < Resolvers::BaseResolver
      type Types::PlatformType, null: true

      description "Find a platform by ID."

      argument :id, ID, required: true

      sig { params(id: T.any(String, Integer)).returns(Platform) }
      def resolve(id:)
        Platform.find(id)
      end
    end
  end
end
