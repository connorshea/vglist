# typed: strict
module Resolvers
  module UserResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::UserType.connection_type, null: true

      description "List all users."

      argument :sort_by, Types::UserSortType, required: false, description: "The order to sort the users in, if any."

      sig { params(sort_by: T.nilable(String)).returns(User::RelationType) }
      def resolve(sort_by: nil)
        # Exclude banned users from the results.
        users = User.all.where(banned: false)

        sort_by.nil? ? users.order(:id) : users.public_send(sort_by.to_sym)
      end
    end
  end
end
