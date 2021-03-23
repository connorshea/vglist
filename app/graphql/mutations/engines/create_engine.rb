# typed: true
class Mutations::Engines::CreateEngine < Mutations::BaseMutation
  description "Create a new game engine. **Not available in production for now.**"

  argument :name, String, required: true, description: 'The name of the engine.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the engine item in Wikidata.'

  field :engine, Types::EngineType, null: true, description: "The engine that was created."

  sig { params(name: String, wikidata_id: T.nilable(T.any(String, Integer))).returns(T::Hash[Symbol, Engine]) }
  def resolve(name:, wikidata_id: nil)
    engine = Engine.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, engine.errors.full_messages.join(", ") unless engine.save

    {
      engine: engine
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    raise GraphQL::ExecutionError, "You aren't allowed to create an engine." unless EnginePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
