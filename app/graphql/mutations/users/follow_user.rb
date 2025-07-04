# typed: true
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
end
