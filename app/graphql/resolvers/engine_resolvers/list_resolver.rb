# frozen_string_literal: true

module Resolvers
  module EngineResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::EngineType.connection_type, null: true

      description "List all game engines."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the engines in. Without one, engines are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return engines whose name contains this text, ignoring case."

      def resolve(sort_by: nil, name_contains: nil)
        engines = Engine.all
        engines = engines.name_contains(name_contains) if name_contains.present?

        ResourceIndex.sort(engines, sort_by)
      end
    end
  end
end
