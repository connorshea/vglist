# typed: strict
module Resolvers
  module PlatformResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::PlatformType.connection_type, null: true

      description "Find a platform by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      sig { params(query: String).returns(Platform::RelationType) }
      def resolve(query:)
        Platform.search(query)
      end
    end
  end
end
