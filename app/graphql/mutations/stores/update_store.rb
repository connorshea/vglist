# typed: true
class Mutations::Stores::UpdateStore < Mutations::BaseMutation
  description "Update an existing game store. **Only available to moderators and admins using a first-party OAuth Application.**"

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

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    store = Store.find(object[:store_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this store." unless StorePolicy.new(@context[:current_user], store).update?

    return true
  end
end
