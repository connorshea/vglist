# typed: true
module Resolvers
  module StoreResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::StoreType.connection_type, null: true

      description "List all stores."

      sig { returns(Store::RelationType) }
      def resolve
        Store.all
      end
    end
  end
end
