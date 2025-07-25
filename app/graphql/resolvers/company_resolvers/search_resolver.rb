module Resolvers
  module CompanyResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::CompanyType.connection_type, null: true

      description "Find a company by searching based on its name."

      argument :query, String, required: true, description: "Name to search by."

      def resolve(query:)
        Company.search(query)
      end
    end
  end
end
