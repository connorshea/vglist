class Mutations::Users::UnbanUser < Mutations::BaseMutation
  description "Unban a user. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :user_id, ID, required: true, description: "ID of user to unban."

  field :user, Types::UserType, null: true, description: "The user that has been unbanned."

  def resolve(user_id:)
    user = User.find(user_id)

    raise GraphQL::ExecutionError, "User has not been banned." unless user.banned?

    user.banned = false

    raise GraphQL::ExecutionError, user.errors.full_messages.join(", ") unless user.save

    {
      user: user
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to unban this user." unless UserPolicy.new(@context[:current_user], user).unban?

    return true
  end
end
