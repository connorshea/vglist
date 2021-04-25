# typed: true
class Mutations::Engines::DeleteEngine < Mutations::BaseMutation
  description "Delete a game engine. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :engine_id, ID, required: true, description: 'The ID of the engine to delete.'

  field :deleted, Boolean, null: true, description: "Whether the engine was successfully deleted."

  sig { params(engine_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(engine_id:)
    engine = Engine.find(engine_id)

    raise GraphQL::ExecutionError, engine.errors.full_messages.join(", ") unless engine.destroy

    {
      deleted: true
    }
  end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    engine = Engine.find(object[:engine_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this engine." unless EnginePolicy.new(@context[:current_user], engine).destroy?

    return true
  end
end
