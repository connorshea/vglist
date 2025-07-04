# typed: true
class Mutations::Stores::DeleteStore < Mutations::BaseMutation
  description "Delete a game store. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :store_id, ID, required: true, description: 'The ID of the store to delete.'

  field :deleted, Boolean, null: true, description: "Whether the store was successfully deleted."

  def resolve(store_id:)
    store = Store.find(store_id)

    raise GraphQL::ExecutionError, store.errors.full_messages.join(", ") unless store.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    store = Store.find(object[:store_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this store." unless StorePolicy.new(@context[:current_user], store).destroy?

    return true
  end
end
