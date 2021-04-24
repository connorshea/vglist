# typed: true
class Mutations::Admin::AddToSteamBlocklist < Mutations::BaseMutation
  description "Add game to Steam blocklist. **Only available to admins using a first-party OAuth Application.**"

  required_permissions :first_party

  argument :name, String, required: true, description: 'The name of the game being added to the blocklist.'
  argument :steam_app_id, Integer, required: true, description: 'ID of the Steam game.'

  field :steam_blocklist_entry, Types::SteamBlocklistEntryType, null: true, description: "The Steam Blocklist entry that was created."

  sig { params(name: String, steam_app_id: Integer).returns(T::Hash[Symbol, SteamBlocklist]) }
  def resolve(name:, steam_app_id:)
    steam_blocklist_entry = SteamBlocklist.create(user_id: @context[:current_user]&.id, name: name, steam_app_id: steam_app_id)

    raise GraphQL::ExecutionError, steam_blocklist_entry.errors.full_messages.join(", ") unless steam_blocklist_entry.save

    {
      steam_blocklist_entry: steam_blocklist_entry
    }
  end

  sig { params(_object: T.untyped).returns(T.nilable(T::Boolean)) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to add this game to the Steam Blocklist." unless AdminPolicy.new(@context[:current_user], nil).add_to_steam_blocklist?

    return true
  end
end
