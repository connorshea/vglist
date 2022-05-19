# typed: true
class Mutations::Users::DeleteUser < Mutations::BaseMutation
  description "Delete a user. **Only available to users deleting their own accounts using a first-party OAuth Application.**"

  argument :user_id, ID, required: true, description: "ID of user to delete."

  field :deleted, Boolean, null: false, description: "Whether the user was deleted successfully or not."

  sig { params(user_id: String).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(user_id:)
    user = User.find_by(id: user_id)

    raise GraphQL::ExecutionError, "User does not exist or could not be deleted." unless user&.destroy!

    {
      deleted: true
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to delete this user." unless UserPolicy.new(@context[:current_user], user).destroy?

    return true
  end
end
