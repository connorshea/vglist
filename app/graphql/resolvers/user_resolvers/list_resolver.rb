# typed: true
module Resolvers
  module UserResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::UserType.connection_type, null: true

      description "List all users."

      sig { returns(User::RelationType) }
      def resolve
        # Exclude banned users from the results.
        User.all.where(banned: false)
      end
    end
  end
end
