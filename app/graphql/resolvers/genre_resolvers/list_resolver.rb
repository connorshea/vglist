# frozen_string_literal: true

module Resolvers
  module GenreResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GenreType.connection_type, null: true

      description "List all genres."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the genres in. Without one, genres are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return genres whose name contains this text, ignoring case."

      def resolve(sort_by: nil, name_contains: nil)
        genres = Genre.all
        genres = genres.name_contains(name_contains) if name_contains.present?

        ResourceIndex.sort(genres, sort_by)
      end
    end
  end
end
