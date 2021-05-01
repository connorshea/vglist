# typed: true
class Mutations::Users::RemoveUserAvatar < Mutations::BaseMutation
  description "Remove the avatar from a user. **Only available when using a first-party OAuth application.**"

  argument :user_id, ID, required: true, description: "ID of user to remove avatar from."

  field :user, Types::UserType, null: false, description: "The user thats avatar was removed."

  sig { params(user_id: String).returns(T::Hash[Symbol, User]) }
  def resolve(user_id:)
    user = User.find_by(id: user_id)

    raise GraphQL::ExecutionError, "User has no avatar attached." unless user&.avatar&.attached?

    user&.avatar&.purge

    {
      user: user
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to remove this user's avatar." unless UserPolicy.new(@context[:current_user], user).remove_avatar?

    return true
  end
end
