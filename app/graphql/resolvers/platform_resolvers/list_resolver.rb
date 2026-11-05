# frozen_string_literal: true

module Resolvers
  module PlatformResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::PlatformType.connection_type, null: true

      description "List all platforms."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the platforms in, if any."

      def resolve(sort_by: nil)
        platforms = Platform.all

        sort_by.nil? ? platforms : platforms.public_send(sort_by.to_sym)
      end
    end
  end
end
