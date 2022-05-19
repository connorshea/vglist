# typed: true
class Mutations::Users::ResetUserLibrary < Mutations::BaseMutation
  description "Reset a user's game library. This will remove the user's entire game library from the database. **Only available to users resetting their own libraries using a first-party OAuth Application.**"

  argument :user_id, ID, required: true, description: "ID of user who's library will be reset."

  field :deleted, Boolean, null: false, description: "Whether the user's library was reset successfully or not."

  sig { params(user_id: String).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(user_id:)
    user = User.find_by(id: user_id)

    raise GraphQL::ExecutionError, "User does not exist." if user.blank?

    game_purchases = GamePurchase.where(user_id: user.id)

    raise GraphQL::ExecutionError, "User could not have their library reset." unless game_purchases.destroy_all

    {
      deleted: true
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to reset this user's library." unless UserPolicy.new(@context[:current_user], user).reset_game_library?

    return true
  end
end
