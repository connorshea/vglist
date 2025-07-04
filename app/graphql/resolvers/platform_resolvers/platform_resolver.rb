module Resolvers
  module PlatformResolvers
    class PlatformResolver < Resolvers::BaseResolver
      type Types::PlatformType, null: true

      description "Find a platform by ID."

      argument :id, ID, required: true

      def resolve(id:)
        Platform.find(id)
      end
    end
  end
end
