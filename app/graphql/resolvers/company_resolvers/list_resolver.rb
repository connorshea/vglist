# frozen_string_literal: true

module Resolvers
  module CompanyResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::CompanyType.connection_type, null: true

      description "List all companies."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the companies in. Without one, companies are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return companies whose name contains this text, ignoring case."

      def resolve(sort_by: nil, name_contains: nil)
        companies = Company.all
        companies = companies.name_contains(name_contains) if name_contains.present?

        ResourceIndex.sort(companies, sort_by)
      end
    end
  end
end
