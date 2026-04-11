---
name: graphql-scaffold
description: Scaffold GraphQL type and CRUD mutations for a Rails model, following vglist conventions.
---

# GraphQL Scaffold

Generate a GraphQL type and Create/Update/Delete mutations for an existing Rails model.

## Input

The user provides a model name (e.g., "Publisher"). Read the model file at `app/models/<model>.rb` to discover columns, associations, and validations before generating anything.

## What to generate

### 1. Type file: `app/graphql/types/<model>_type.rb`

Follow the pattern in existing types (CompanyType, PlatformType, GenreType):

```ruby
# frozen_string_literal: true

module Types
  class <Model>Type < Types::BaseObject
    description "<Description of the entity>"

    field :id, ID, null: false, description: "ID of the <model>."
    field :name, String, null: false, description: "Name of the <model>."
    # Add fields for each database column. Use these type mappings:
    #   string/text  -> String
    #   integer      -> Integer
    #   float/decimal -> Float
    #   boolean      -> Boolean
    #   date         -> GraphQL::Types::ISO8601Date
    #   datetime     -> GraphQL::Types::ISO8601DateTime
    #   references   -> ID (for foreign keys)
    # Every field MUST have a description.
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this <model> was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this <model> was last updated."

    # Associations: use ConnectionType for has_many
    # field :games, GameType.connection_type, null: false, description: "Games associated with this <model>."
    #
    # If the association uses `with_attached_cover`, add a resolver method:
    # def games
    #   @object.games.with_attached_cover
    # end
  end
end
```

### 2. Create mutation: `app/graphql/mutations/<models>/create_<model>.rb`

```ruby
# frozen_string_literal: true

class Mutations::<Models>::Create<Model> < Mutations::BaseMutation
  description "Create a new <model>. **Only available to moderators and admins using a first-party OAuth Application.**"

  # Arguments: required fields from the model's validations.
  # Use `required: true` for validated presence fields, `required: false` for optional.
  argument :name, String, required: true, description: 'The name of the <model>.'
  argument :wikidata_id, ID, required: true, description: 'The ID of the <model> item in Wikidata.'
  # For has_many through associations, use array ID arguments:
  # argument :game_ids, [ID], required: false, description: 'The ID(s) of associated games.'

  field :<model>, Types::<Model>Type, null: true, description: "The <model> that was created."

  def resolve(name:, wikidata_id:)
    <model> = <Model>.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, <model>.errors.full_messages.join(", ") unless <model>.save

    {
      <model>: <model>
    }
  end

  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a <model>." unless <Model>Policy.new(@context[:current_user], nil).create?

    return true
  end
end
```

### 3. Update mutation: `app/graphql/mutations/<models>/update_<model>.rb`

- Takes `<model>_id` as required ID argument.
- All other arguments are `required: false`.
- Uses `**args` splat pattern to avoid nil-overwriting existing values.
- In `authorized?`, fetches the record by ID and checks `<Model>Policy.new(@context[:current_user], <model>).update?`.

```ruby
# frozen_string_literal: true

class Mutations::<Models>::Update<Model> < Mutations::BaseMutation
  description "Update an existing <model>. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :<model>_id, ID, required: true, description: 'The ID of the <model> record.'
  argument :name, String, required: false, description: 'The name of the <model>.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the <model> item in Wikidata.'

  field :<model>, Types::<Model>Type, null: false, description: "The <model> that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  def resolve(<model>_id:, **args)
    <model> = <Model>.find(<model>_id)

    raise GraphQL::ExecutionError, <model>.errors.full_messages.join(", ") unless <model>.update(**args)

    {
      <model>: <model>
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    <model> = <Model>.find(object[:<model>_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this <model>." unless <Model>Policy.new(@context[:current_user], <model>).update?

    return true
  end
end
```

### 4. Delete mutation: `app/graphql/mutations/<models>/delete_<model>.rb`

```ruby
# frozen_string_literal: true

class Mutations::<Models>::Delete<Model> < Mutations::BaseMutation
  description "Delete a <model>. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :<model>_id, ID, required: true, description: 'The ID of the <model> to delete.'

  field :deleted, Boolean, null: true, description: "Whether the <model> was successfully deleted."

  def resolve(<model>_id:)
    <model> = <Model>.find(<model>_id)

    raise GraphQL::ExecutionError, <model>.errors.full_messages.join(", ") unless <model>.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    <model> = <Model>.find(object[:<model>_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this <model>." unless <Model>Policy.new(@context[:current_user], <model>).destroy?

    return true
  end
end
```

### 5. Register in `app/graphql/types/mutation_type.rb`

Add three field lines in the appropriate alphabetical section:

```ruby
# <Model> mutations
field :create_<model>, mutation: Mutations::<Models>::Create<Model>
field :update_<model>, mutation: Mutations::<Models>::Update<Model>
field :delete_<model>, mutation: Mutations::<Models>::Delete<Model>
```

## After generating

Remind the user to:
1. Verify a Pundit policy exists at `app/policies/<model>_policy.rb` with `create?`, `update?`, and `destroy?` methods.
2. Run `bundle exec rake graphql:schema:idl` to regenerate `schema.graphql`.
3. Run `cd frontend && yarn codegen` to regenerate TypeScript types.
4. Add query resolvers to `app/graphql/types/query_type.rb` if the entity needs query access.

## Rules

- Every field and argument MUST have a `description:` string.
- Use `frozen_string_literal: true` pragma on every Ruby file.
- Pluralize the module name for mutations (e.g., `Mutations::Companies::CreateCompany`).
- The create mutation's return field is `null: true`; update is `null: false`; delete returns `deleted` as `null: true`.
- Do NOT use InputObject types — define arguments directly on the mutation.
- For complex models with many associations (like Game), list each explicit keyword argument in `resolve()` with defaults instead of using `**args`.
- For simpler models, the update mutation can use `def resolve(<model>_id:, **args)` with `<model>.update(**args)`.
