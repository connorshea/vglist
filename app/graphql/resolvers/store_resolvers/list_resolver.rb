# typed: strict
module Resolvers
  module StoreResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::StoreType.connection_type, null: true

      description "List all stores."

      def resolve
        Store.all
      end
    end
  end
end
