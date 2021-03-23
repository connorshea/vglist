# typed: true
class Mutations::Engines::UpdateEngine < Mutations::BaseMutation
  description "Update an existing game engine. **Not available in production for now.**"

  argument :engine_id, ID, required: true, description: 'The ID of the engine record.'
  argument :name, String, required: false, description: 'The name of the engine.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the engine item in Wikidata.'

  field :engine, Types::EngineType, null: false, description: "The engine that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  sig { params(engine_id: T.any(String, Integer), args: T.untyped).returns(T::Hash[Symbol, Engine]) }
  def resolve(engine_id:, **args)
    engine = Engine.find(engine_id)

    raise GraphQL::ExecutionError, engine.errors.full_messages.join(", ") unless engine.update(**args)

    {
      engine: engine
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    engine = Engine.find(object[:engine_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this engine." unless EnginePolicy.new(@context[:current_user], engine).update?

    return true
  end
end
