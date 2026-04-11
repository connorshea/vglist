# frozen_string_literal: true

module Resolvers
  module UserResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::UserType.connection_type, null: true

      description "Find a user by searching based on its username."

      argument :query, String, required: true, description: "Username to search by."

      def resolve(query:)
        User.search(query).with_attached_avatar
      end
    end
  end
end
