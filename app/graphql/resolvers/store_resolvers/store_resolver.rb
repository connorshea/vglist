# typed: strict
module Resolvers
  module StoreResolvers
    class StoreResolver < Resolvers::BaseResolver
      type Types::StoreType, null: true

      description "Find a store by ID."

      argument :id, ID, required: true

      def resolve(id:)
        Store.find(id)
      end
    end
  end
end
