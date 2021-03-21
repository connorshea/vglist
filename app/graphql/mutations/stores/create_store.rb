# typed: true
class Mutations::Stores::CreateStore < Mutations::BaseMutation
  description "Create a new game store. **Not available in production for now.**"

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

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    raise GraphQL::ExecutionError, "You aren't allowed to create a store." unless StorePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
