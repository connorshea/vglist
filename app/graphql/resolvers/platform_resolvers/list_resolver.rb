# typed: strict
module Resolvers
  module PlatformResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::PlatformType.connection_type, null: true

      description "List all platforms."

      sig { returns(Platform::RelationType) }
      def resolve
        Platform.all
      end
    end
  end
end
