# frozen_string_literal: true

module Resolvers
  module GenreResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GenreType.connection_type, null: true

      description "List all genres."

      argument :sort_by, Types::Enums::ResourceSortType, required: false, description: "The order to sort the genres in, if any."

      def resolve(sort_by: nil)
        genres = Genre.all

        sort_by.nil? ? genres : genres.public_send(sort_by.to_sym)
      end
    end
  end
end
