# typed: true
module Resolvers
  module UserResolvers
    class CurrentUserResolver < Resolvers::BaseResolver
      type Types::UserType, null: true

      description "Get the currently authenticated user."

      sig { returns(T.nilable(User)) }
      def resolve
        context[:current_user]
      end
    end
  end
end
