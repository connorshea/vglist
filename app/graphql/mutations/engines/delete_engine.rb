# typed: true
class Mutations::Engines::DeleteEngine < Mutations::BaseMutation
  description "Delete a game engine. **Only available to moderators and admins.** **Not available in production for now.**"

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

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    engine = Engine.find(object[:engine_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this engine." unless EnginePolicy.new(@context[:current_user], engine).destroy?

    return true
  end
end
