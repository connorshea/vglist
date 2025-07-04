module Resolvers
  module CompanyResolvers
    class CompanyResolver < Resolvers::BaseResolver
      type Types::CompanyType, null: true

      description "Find a company by ID."

      argument :id, ID, required: true

      def resolve(id:)
        Company.find(id)
      end
    end
  end
end
