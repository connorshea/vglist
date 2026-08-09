# frozen_string_literal: true

class Mutations::Users::FollowUser < Mutations::BaseMutation
  description "Follow a user."

  argument :user_id, ID, required: true, description: "ID of user to follow."

  field :user, Types::UserType, null: true, description: "The user being followed."

  def resolve(user_id:)
    user = User.find(user_id)

    relationship = Relationship.create(follower: @context[:current_user], followed: user)

    raise GraphQL::ExecutionError, relationship.errors.full_messages.join(", ") unless relationship.save

    {
      user: user
    }
  end

  def authorized?(object)
    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to follow this user." unless RelationshipPolicy.new(@context[:current_user], user).create?

    return true
  end
end
