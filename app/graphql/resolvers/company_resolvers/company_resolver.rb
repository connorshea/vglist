# typed: strict
module Resolvers
  module CompanyResolvers
    class CompanyResolver < Resolvers::BaseResolver
      type Types::CompanyType, null: true

      description "Find a company by ID."

      argument :id, ID, required: true

      sig { params(id: T.any(String, Integer)).returns(Company) }
      def resolve(id:)
        Company.find(id)
      end
    end
  end
end
