# typed: true
class Mutations::Stores::UpdateStore < Mutations::BaseMutation
  description "Update an existing game store. **Only available to moderators and admins.** **Not available in production for now.**"

  argument :store_id, ID, required: true, description: 'The ID of the store record.'
  argument :name, String, required: false, description: 'The name of the store.'

  field :store, Types::StoreType, null: false, description: "The store that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  sig { params(store_id: T.any(String, Integer), args: T.untyped).returns(T::Hash[Symbol, Store]) }
  def resolve(store_id:, **args)
    store = Store.find(store_id)

    raise GraphQL::ExecutionError, store.errors.full_messages.join(", ") unless store.update(**args)

    {
      store: store
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    store = Store.find(object[:store_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this store." unless StorePolicy.new(@context[:current_user], store).update?

    return true
  end
end
