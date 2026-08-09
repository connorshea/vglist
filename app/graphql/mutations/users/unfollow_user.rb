# frozen_string_literal: true

class Mutations::Users::UnfollowUser < Mutations::BaseMutation
  description "Unfollow a user."

  argument :user_id, ID, required: true, description: "ID of user to unfollow."

  field :user, Types::UserType, null: true, description: "The user being unfollowed."

  def resolve(user_id:)
    user = User.find(user_id)

    relationship = Relationship.find_by(follower: @context[:current_user], followed: user)

    raise GraphQL::ExecutionError, "Relationship does not exist or could not be deleted." unless relationship&.destroy

    {
      user: user
    }
  end

  def authorized?(object)
    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to unfollow this user." unless RelationshipPolicy.new(@context[:current_user], user).destroy?

    return true
  end
end
