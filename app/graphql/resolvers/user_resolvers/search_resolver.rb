# frozen_string_literal: true

module Resolvers
  module UserResolvers
    class SearchResolver < Resolvers::BaseResolver
      type Types::UserType.connection_type, null: true

      description "Find a user by searching based on its username."

      search_query_argument "Username to search by."

      def resolve(query:)
        # Banned users are left out of every user listing, as in `users`.
        User.search(query).where(banned: false).with_attached_avatar
      end
    end
  end
end
