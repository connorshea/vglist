# typed: true
class Mutations::Engines::CreateEngine < Mutations::BaseMutation
  description "Create a new game engine. **Only available when using a first-party OAuth Application.**"

  required_permissions :first_party

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

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to create an engine." unless EnginePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
