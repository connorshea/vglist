# typed: true
class Mutations::Users::ConnectSteam < Mutations::BaseMutation
  description "Connect a Steam account for a user. **Only available to users connecting their own Steam account when using a first-party OAuth application.**"

  argument :user_id, ID, required: true, description: 'ID of the User that we want to connect this Steam account to'
  argument :steam_username, String, required: true, description: 'The Steam username of the account being connected.'

  field :connected, Boolean, null: false, description: "Whether the account was connected successfully."

  sig { params(user_id: T.any(String, Integer), steam_username: String).returns(T::Hash[Symbol, T.untyped]) }
  def resolve(user_id:, steam_username:)
    user = User.find(user_id)

    # Resolve the numerical Steam ID based on the provided username.
    uri = URI("https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&vanityurl=#{steam_username}")
    response = Net::HTTP.get_response(uri)
    json = JSON.parse(response.body)

    steam_id = json.dig("response", "steamid")

    raise GraphQL::ExecutionError, 'No Steam ID was found in the response from the Steam API.' if steam_id.nil?

    # If one already exists, don't create it.
    # If not, create it and pass in the steam_id and steam_profile_url.
    @steam_account = ExternalAccount.create_with(
      steam_id: steam_id,
      steam_profile_url: "https://steamcommunity.com/id/#{steam_username}/"
    ).find_or_create_by!(
      user_id: user.id,
      account_type: :steam
    )

    raise GraphQL::ExecutionError, 'Unable to find a Steam account with that username.' unless @steam_account.save!

    {
      connected: true
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to update this user's Steam account." unless UserPolicy.new(@context[:current_user], user).connect_steam?

    return true
  end
end
