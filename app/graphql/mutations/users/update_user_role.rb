# typed: true
class Mutations::Users::UpdateUserRole < Mutations::BaseMutation
  description "Update a user's role. **Only available to admins using a first-party OAuth Application.**"

  argument :user_id, ID, required: true, description: "ID of user to update the role of."
  argument :role, Types::UserRoleType, required: true, description: "The role to assign to the user."

  field :user, Types::UserType, null: true, description: "The user that has been updated."

  sig { params(user_id: T.any(String, Integer), role: String).returns(T::Hash[Symbol, User]) }
  def resolve(user_id:, role:)
    user = User.find(user_id)

    raise GraphQL::ExecutionError, "User already has the #{role.downcase} role." if user.role == role

    user.role = role

    raise GraphQL::ExecutionError, user.errors.full_messages.join(", ") unless user.save

    {
      user: user
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to update the role of this user." unless UserPolicy.new(@context[:current_user], user).update_role?

    return true
  end
end
