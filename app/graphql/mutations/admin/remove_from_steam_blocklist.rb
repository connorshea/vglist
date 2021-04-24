# typed: true
class Mutations::Admin::RemoveFromSteamBlocklist < Mutations::BaseMutation
  description "Remove game from Steam blocklist. **Only available to admins using a first-party OAuth Application.**"

  required_permissions :first_party

  argument :steam_blocklist_entry_id, ID, required: true, description: 'The ID of the blocklist entry.'

  field :deleted, Boolean, null: false, description: "Whether the blocklist entry was deleted."

  sig { params(steam_blocklist_entry_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(steam_blocklist_entry_id:)
    steam_blocklist_entry = SteamBlocklist.find_by(id: steam_blocklist_entry_id)

    raise GraphQL::ExecutionError, steam_blocklist_entry&.errors&.full_messages&.join(", ") unless steam_blocklist_entry&.destroy

    {
      deleted: true
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to remove a Steam blocklist entry." unless AdminPolicy.new(@context[:current_user], nil).remove_from_steam_blocklist?

    return true
  end
end
