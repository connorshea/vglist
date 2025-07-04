# typed: true
class Mutations::Users::BanUser < Mutations::BaseMutation
  description "Ban a user. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :user_id, ID, required: true, description: "ID of user to ban."

  field :user, Types::UserType, null: true, description: "The user that has been banned."

  def resolve(user_id:)
    user = User.find(user_id)

    raise GraphQL::ExecutionError, "User has already been banned." if user.banned?

    user.banned = true
    # Revoke any special roles from the banned user.
    user.role = :member unless user.member?

    raise GraphQL::ExecutionError, user.errors.full_messages.join(", ") unless user.save

    {
      user: user
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to ban this user." unless UserPolicy.new(@context[:current_user], user).ban?

    return true
  end
end
