# typed: true
class Mutations::UnfollowUser < Mutations::BaseMutation
  description "Unfollow a user."

  argument :user_id, ID, required: true, description: "ID of user to unfollow."

  field :user, Types::UserType, null: true

  def resolve(user_id:)
    user = User.find(user_id)

    relationship = Relationship.find_by(follower: @context[:current_user], followed: user)

    raise GraphQL::ExecutionError, "Relationship does not exist or could not be deleted." unless relationship&.destroy

    {
      user: user
    }
  end
end
