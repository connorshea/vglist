module Resolvers
  module UserResolvers
    class CurrentUserResolver < Resolvers::BaseResolver
      type Types::UserType, null: true

      description "Get the currently authenticated user."

      def resolve
        context[:current_user]
      end
    end
  end
end
