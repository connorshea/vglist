class Mutations::Engines::CreateEngine < Mutations::BaseMutation
  description "Create a new game engine. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the engine.'
  argument :wikidata_id, ID, required: true, description: 'The ID of the engine item in Wikidata.'

  field :engine, Types::EngineType, null: true, description: "The engine that was created."

  def resolve(name:, wikidata_id:)
    engine = Engine.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, engine.errors.full_messages.join(", ") unless engine.save

    {
      engine: engine
    }
  end

  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create an engine." unless EnginePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
