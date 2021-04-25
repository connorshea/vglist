# typed: true
class Mutations::Stores::CreateStore < Mutations::BaseMutation
  description "Create a new game store. **Only available when using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the store.'

  field :store, Types::StoreType, null: true, description: "The store that was created."

  sig { params(name: String).returns(T::Hash[Symbol, Store]) }
  def resolve(name:)
    store = Store.new(name: name)

    raise GraphQL::ExecutionError, store.errors.full_messages.join(", ") unless store.save

    {
      store: store
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a store." unless StorePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
