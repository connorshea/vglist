module Resolvers
  module StoreResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::StoreType.connection_type, null: true

      description "Find a store by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      def resolve(query:)
        Store.search(query)
      end
    end
  end
end
