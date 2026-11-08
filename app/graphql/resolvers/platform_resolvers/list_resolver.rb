# frozen_string_literal: true

module Resolvers
  module PlatformResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::PlatformType.connection_type, null: true

      description "List all platforms."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the platforms in. Without one, platforms are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return platforms whose name contains this text, ignoring case."

      def resolve(sort_by: nil, name_contains: nil)
        platforms = Platform.all
        platforms = platforms.name_contains(name_contains) if name_contains.present?

        ResourceIndex.sort(platforms, sort_by)
      end
    end
  end
end
