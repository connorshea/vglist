# typed: strict
module Resolvers
  module UserResolvers
    class UserResolver < Resolvers::BaseResolver
      type Types::UserType, null: true

      description "Find a user. May only use one or the other."

      argument :id, ID, required: false, description: "Find a user by their ID."
      argument :username, String, required: false, description: "Find a user by their username."

      # Use validator to validate that one of the arguments is being used.
      validates required: {
        one_of: [:id, :username],
        message: 'Cannot provide more than one argument to user at a time.'
      }

      sig { params(id: T.nilable(T.any(String, Integer)), username: T.nilable(String)).returns(T.nilable(User)) }
      def resolve(id: nil, username: nil)
        if !id.nil?
          User.find(id)
        elsif !username.nil?
          User.find_by(username: username)
        end
      end
    end
  end
end
