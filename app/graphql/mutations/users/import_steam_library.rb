# typed: true
class Mutations::Users::ImportSteamLibrary < Mutations::BaseMutation
  description "Import's the Steam library of the user. **Only available to users importing their own Steam library when using a first-party OAuth application.**"

  argument :user_id, ID, required: true, description: "ID of user who's Steam library we want to import."
  argument :update_hours, Boolean, required: false, description: "Whether the importer should update the hours on the imported games if they've already been added to the user's library previously."

  field :user, Types::UserType, null: false, description: "The user who's library was updated."
  field :added_games, [Types::GameType], null: false, description: "The games that were added to the user's library."
  field :updated_games, [Types::GameType], null: false, description: "The games that were updated in the user's library."
  field :added_games_count, Integer, null: false, description: "The number of games that were added to the user's library."
  field :unmatched_count, Integer, null: false, description: "The number of games where a match couldn't be found in the database."
  field :updated_games_count, Integer, null: false, description: "The number of games in the user's library that were updated."

  sig { params(user_id: T.any(String, Integer), update_hours: T::Boolean).returns(T::Hash[Symbol, T.untyped]) }
  def resolve(user_id:, update_hours: false)
    user = User.find(user_id)

    result = SteamImportService.new(user: user, update_hours: update_hours).call

    {
      user: user,
      added_games: result.added_games,
      updated_games: result.updated_games,
      added_games_count: result.added_games.count,
      unmatched_count: result.unmatched.count,
      updated_games_count: result.updated_games.count
    }
  rescue SteamImportService::NoGamesError
    # If no games are returned, return an error message.
    raise GraphQL::ExecutionError, "Unable to find any games in your Steam library. Are you sure it's public and that you've connected the correct account?"
  rescue SteamImportService::Error
    # If the API request errors, return a generic error message.
    raise GraphQL::ExecutionError, "Steam API Request failed."
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to import games for this user." unless UserPolicy.new(@context[:current_user], user).steam_import?

    return true
  end
end
