# typed: true
class Mutations::Users::DisconnectSteam < Mutations::BaseMutation
  description "Disconnect a user's Steam account. **Only available to users disconnecting their own Steam account when using a first-party OAuth application.**"

  argument :user_id, ID, required: true, description: 'The ID of the User that we want to disconnect a Steam account from.'

  field :disconnected, Boolean, null: false, description: "Whether the account was disconnected successfully."

  sig { params(user_id: T.any(String, Integer)).returns(T::Hash[Symbol, T.untyped]) }
  def resolve(user_id:)
    user = User.find(user_id)

    steam_account = ExternalAccount.find_by(user_id: user.id, account_type: :steam)

    raise GraphQL::ExecutionError, 'No Steam account could be found for this user.' if steam_account.nil?

    raise GraphQL::ExecutionError, 'Unable to disconnect Steam account for this user.' unless steam_account.destroy

    {
      connected: true
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to disconnect this user's Steam account." unless UserPolicy.new(@context[:current_user], user).disconnect_steam?

    return true
  end
end
