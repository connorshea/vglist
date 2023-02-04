# typed: true
class Mutations::Admin::RemoveFromWikidataBlocklist < Mutations::BaseMutation
  description "Remove game from Wikidata blocklist. **Only available to admins using a first-party OAuth Application.**"

  argument :wikidata_blocklist_entry_id, ID, required: true, description: 'The ID of the blocklist entry.'

  field :deleted, Boolean, null: false, description: "Whether the blocklist entry was deleted."

  sig { params(wikidata_blocklist_entry_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(wikidata_blocklist_entry_id:)
    wikidata_blocklist_entry = WikidataBlocklist.find(wikidata_blocklist_entry_id)

    raise GraphQL::ExecutionError, wikidata_blocklist_entry.errors.full_messages.join(", ") unless wikidata_blocklist_entry.destroy

    {
      deleted: true
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to remove a Wikidata blocklist entry." unless AdminPolicy.new(@context[:current_user], nil).remove_from_wikidata_blocklist?

    return true
  end
end
