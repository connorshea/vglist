# frozen_string_literal: true

module Resolvers
  module UserResolvers
    class LibraryComparisonResolver < Resolvers::BaseResolver
      type Types::LibraryComparisonType, null: true

      description "Compare two users' game libraries. Returns `null` if either user doesn't exist. Both users' libraries must be visible to the current user."

      argument :user_a_slug, String, required: true, description: "The slug of the first user to compare."
      argument :user_b_slug, String, required: true, description: "The slug of the second user to compare."

      def resolve(user_a_slug:, user_b_slug:)
        user_a = User.find_by(slug: user_a_slug)
        user_b = User.find_by(slug: user_b_slug)
        return nil if user_a.nil? || user_b.nil?

        # Comparing reveals what's in both libraries, so the viewer has to be
        # allowed to see each of them.
        [user_a, user_b].each do |user|
          raise GraphQL::ExecutionError, "You aren't allowed to see #{user.username}'s library." unless UserPolicy.new(@context[:current_user], user).compare?
        end

        LibraryComparison.new(user_a, user_b)
      end
    end
  end
end
