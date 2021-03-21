# typed: true
class Mutations::Admin::AddToWikidataBlocklist < Mutations::BaseMutation
  description "Add to game Wikidata blocklist."

  argument :name, String, required: true, description: 'The user being followed.'
  argument :wikidata_id, Integer, required: true, description: 'ID of the Wikidata item.'

  field :wikidata_blocklist_entry, Types::WikidataBlocklistEntryType, null: true, description: "The Wikidata Blocklist entry that was created."

  sig { params(name: String, wikidata_id: Integer).returns(T::Hash[Symbol, WikidataBlocklist]) }
  def resolve(name:, wikidata_id:)
    wikidata_blocklist_entry = WikidataBlocklist.create(user_id: @context[:current_user]&.id, name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, wikidata_blocklist_entry.errors.full_messages.join(", ") unless wikidata_blocklist_entry.save

    {
      wikidata_blocklist_entry: wikidata_blocklist_entry
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(_object: T.untyped).returns(T.nilable(T::Boolean)) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to add this game to the Wikidata Blocklist." unless AdminPolicy.new(@context[:current_user], nil).remove_from_wikidata_blocklist?

    return true
  end
end
