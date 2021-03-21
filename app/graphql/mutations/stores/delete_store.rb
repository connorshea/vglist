# typed: true
class Mutations::Stores::DeleteStore < Mutations::BaseMutation
  description "Delete a game store. **Only available to moderators and admins.** **Not available in production for now.**"

  argument :store_id, ID, required: true, description: 'The ID of the store to delete.'

  field :deleted, Boolean, null: true, description: "Whether the store was successfully deleted."

  sig { params(store_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(store_id:)
    store = Store.find(store_id)

    raise GraphQL::ExecutionError, store.errors.full_messages.join(", ") unless store.destroy

    {
      deleted: true
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    store = Store.find(object[:store_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this store." unless StorePolicy.new(@context[:current_user], store).destroy?

    return true
  end
end
