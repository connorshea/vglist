# typed: strict
module Resolvers
  module UserResolvers
    class UserResolver < Resolvers::BaseResolver
      type Types::UserType, null: true

      description "Find a user. May only use one argument at a time."

      argument :id, ID, required: false, description: "Find a user by their ID."
      argument :username, String, required: false, description: "Find a user by their username."
      argument :slug, String, required: false, description: "Find a user by their slug (their sanitized username, used in URLs for user pages)."

      # Use validator to validate that one of the arguments is being used.
      validates required: {
        one_of: [:id, :username, :slug],
        message: 'Cannot provide more than one argument to user at a time.'
      }

      def resolve(id: nil, username: nil, slug: nil)
        if !id.nil?
          User.find_by(id: id)
        elsif !username.nil?
          User.find_by(username: username)
        elsif !slug.nil?
          User.find_by(slug: slug)
        end
      end
    end
  end
end
