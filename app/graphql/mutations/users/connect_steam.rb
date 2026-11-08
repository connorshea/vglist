# frozen_string_literal: true

class Mutations::Users::ConnectSteam < Mutations::BaseMutation
  description "Connect a Steam account for a user. **Only available to users connecting their own Steam account.**"

  argument :user_id, ID, required: true, description: 'ID of the User that we want to connect this Steam account to'
  argument :steam_username, String, required: true, description: 'The Steam username of the account being connected.'

  field :connected, Boolean, null: false, description: "Whether the account was connected successfully."

  def resolve(user_id:, steam_username:)
    user = User.find(user_id)

    steam_id, steam_profile_url = resolve_steam_account(steam_username.strip)

    # steam_id is unique across accounts, so say so plainly instead of letting
    # the uniqueness validation surface as an internal error.
    raise GraphQL::ExecutionError, "That Steam account is already connected to another vglist account." if steam_account_taken?(steam_id, user)

    # If one already exists, don't create it.
    # If not, create it and pass in the steam_id and steam_profile_url.
    @steam_account = ExternalAccount.create_with(
      steam_id: steam_id,
      steam_profile_url: steam_profile_url
    ).find_or_create_by!(
      user_id: user.id,
      account_type: :steam
    )

    raise GraphQL::ExecutionError, 'Unable to find a Steam account with that username.' unless @steam_account.save!

    {
      connected: true
    }
  end

  def authorized?(object)
    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to connect this user's Steam account." unless UserPolicy.new(@context[:current_user], user).connect_steam?

    return true
  end

  private

  STEAM_ID64_PATTERN = /\A7656\d{13}\z/
  PROFILES_URL_PATTERN = %r{\A(?:https?://)?(?:www\.)?steamcommunity\.com/profiles/(7656\d{13})/?(?:[?#].*)?\z}i
  VANITY_URL_PATTERN = %r{\A(?:https?://)?(?:www\.)?steamcommunity\.com/id/([^/?#]+)/?(?:[?#].*)?\z}i

  # Accepts a vanity name ("foo"), a vanity profile URL
  # (https://steamcommunity.com/id/foo/), a numeric profile URL
  # (https://steamcommunity.com/profiles/7656.../) or a bare SteamID64, and
  # returns the SteamID64 along with the canonical profile URL.
  def resolve_steam_account(input)
    numeric_id = input[STEAM_ID64_PATTERN] || input[PROFILES_URL_PATTERN, 1]
    return [numeric_id, "https://steamcommunity.com/profiles/#{numeric_id}/"] if numeric_id

    vanity = input[VANITY_URL_PATTERN, 1] || input
    [resolve_vanity_url(vanity), "https://steamcommunity.com/id/#{ERB::Util.url_encode(vanity)}/"]
  end

  def resolve_vanity_url(vanity)
    # The username is user-provided, so it has to be escaped rather than
    # interpolated into the query string, otherwise the user can append or
    # override parameters on a request that carries our Steam Web API key.
    uri = URI("https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/")
    uri.query = URI.encode_www_form(
      key: ENV['STEAM_WEB_API_KEY'],
      vanityurl: vanity
    )

    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise GraphQL::ExecutionError, 'The Steam API took too long to respond.'
    end

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError
      raise GraphQL::ExecutionError, 'The Steam API returned an unexpected response.'
    end

    # Steam answers an unknown vanity name with success: 42 ("No match").
    raise GraphQL::ExecutionError, "Unable to find a Steam account with the username \"#{vanity}\"." if json.dig("response", "success") == 42

    steam_id = json.dig("response", "steamid")
    raise GraphQL::ExecutionError, 'No Steam ID was found in the response from the Steam API.' if steam_id.nil?

    steam_id
  end

  def steam_account_taken?(steam_id, user)
    ExternalAccount.where(steam_id: steam_id).where.not(user_id: user.id).exists?
  end
end
