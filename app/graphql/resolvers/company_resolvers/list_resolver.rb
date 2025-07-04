module Resolvers
  module CompanyResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::CompanyType.connection_type, null: true

      description "List all companies."

      def resolve
        Company.all
      end
    end
  end
end
