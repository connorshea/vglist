# typed: true
class Mutations::Admin::AddToWikidataBlocklist < Mutations::BaseMutation
  description "Add game to Wikidata blocklist and remove Wikidata ID from any game that current has it. **Only available to admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the game being added to the blocklist.'
  argument :wikidata_id, Integer, required: true, description: 'ID of the Wikidata item.'

  field :wikidata_blocklist_entry, Types::WikidataBlocklistEntryType, null: true, description: "The Wikidata Blocklist entry that was created."

  sig { params(name: String, wikidata_id: Integer).returns(T::Hash[Symbol, WikidataBlocklist]) }
  def resolve(name:, wikidata_id:)
    # Find the existing game with this Wikidata ID and remove it from the
    # record, if it exists.
    game = Game.find_by(wikidata_id: wikidata_id)
    game&.update!(wikidata_id: nil)

    wikidata_blocklist_entry = WikidataBlocklist.create(user_id: @context[:current_user]&.id, name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, wikidata_blocklist_entry.errors.full_messages.join(", ") unless wikidata_blocklist_entry.save

    {
      wikidata_blocklist_entry: wikidata_blocklist_entry
    }
  end

  sig { params(_object: T.untyped).returns(T.nilable(T::Boolean)) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to add this game to the Wikidata Blocklist." unless AdminPolicy.new(@context[:current_user], nil).remove_from_wikidata_blocklist?

    return true
  end
end
