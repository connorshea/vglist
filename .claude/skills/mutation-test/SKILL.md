---
name: mutation-test
description: Scaffold RSpec request specs for GraphQL mutations, following vglist testing conventions.
---

# Mutation Test Scaffolder

Generate RSpec request specs for GraphQL Create, Update, and/or Delete mutations.

## Input

The user provides a mutation name or model name (e.g., "CreateCompany" or "Company"). Read the corresponding mutation file(s) at `app/graphql/mutations/<models>/` to discover arguments, return fields, and authorization rules.

## Output structure

Create spec file(s) at `spec/requests/api/mutations/<models>/<mutation_name>_spec.rb`.

## Conventions

### File header and setup

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "<MutationName> Mutation API", type: :request do
  describe "Mutation <action>s a <model> record" do
    let(:user) { create(:confirmed_moderator) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
```

### API request helper

Use `api_request(query_string, variables: { ... }, token: access_token)`.

- Variable keys are automatically camelCased by the helper — pass them as **snake_case** symbols in the `variables` hash.
- The helper returns a `VglistApiRequestResponse` object.

### Assertions

- **Success data**: `result.graphql_dig(:create_<model>, :<model>, :name)` — symbols are auto-camelized.
- **Connection fields**: `result.graphql_dig(:create_<model>, :<model>, :games)` returns `{ nodes: [{ id: "1" }] }` with symbolized keys.
- **Errors**: `result.to_h['errors'].first['message']` — use `to_h`, not `graphql_dig`.
- **IDs in responses** are always strings — use `.to_s` when comparing factory record IDs.

### Create mutation spec pattern

```ruby
context 'when the current user is a moderator' do
  let(:query_string) do
    <<-GRAPHQL
      mutation($name: String!, $wikidataId: ID!) {
        create<Model>(name: $name, wikidataId: $wikidataId) {
          <model> {
            name
            wikidataId
          }
        }
      }
    GRAPHQL
  end

  it "increases <Model> count by 1" do
    expect do
      api_request(query_string, variables: { name: 'Test', wikidata_id: 123 }, token: access_token)
    end.to change(<Model>, :count).by(1)
  end

  it "returns basic data for <model> after creating it" do
    result = api_request(query_string, variables: { name: 'Test', wikidata_id: 123 }, token: access_token)

    expect(result.graphql_dig(:create_<model>, :<model>)).to eq({
      name: 'Test',
      wikidataId: 123
    })
  end
end
```

### Update mutation spec pattern

```ruby
context 'when the current user is a moderator' do
  let!(:<model>) { create(:<model>) }
  let(:query_string) do
    <<-GRAPHQL
      mutation($<model>Id: ID!, $name: String) {
        update<Model>(<model>Id: $<model>Id, name: $name) {
          <model> {
            name
          }
        }
      }
    GRAPHQL
  end

  it "does not change <Model> count" do
    expect do
      api_request(query_string, variables: { <model>_id: <model>.id, name: 'Updated' }, token: access_token)
    end.not_to change(<Model>, :count)
  end

  it "returns updated data" do
    result = api_request(query_string, variables: { <model>_id: <model>.id, name: 'Updated' }, token: access_token)

    expect(result.graphql_dig(:update_<model>, :<model>, :name)).to eq('Updated')
  end
end
```

### Delete mutation spec pattern

```ruby
context "when the current user is an admin" do
  let(:user) { create(:confirmed_admin) }
  let!(:<model>) { create(:<model>) }
  let(:query_string) do
    <<-GRAPHQL
      mutation($<model>Id: ID!) {
        delete<Model>(<model>Id: $<model>Id) {
          deleted
        }
      }
    GRAPHQL
  end

  it "decreases <Model> count by 1" do
    expect do
      api_request(query_string, variables: { <model>_id: <model>.id }, token: access_token)
    end.to change(<Model>, :count).by(-1)
  end

  it "returns true after deletion" do
    result = api_request(query_string, variables: { <model>_id: <model>.id }, token: access_token)

    expect(result.graphql_dig(:delete_<model>, :deleted)).to eq(true)
  end
end
```

### Authorization failure test (include for EACH mutation)

```ruby
context 'when the current user is a normal member' do
  let(:user) { create(:confirmed_user) }

  it "does not change <Model> count" do
    expect do
      result = api_request(query_string, variables: { ... }, token: access_token)
      expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to <action> a <model>.")
    end.not_to change(<Model>, :count)
  end
end
```

### Role iteration shorthand

For simpler entities where moderators AND admins can perform the action:

```ruby
[:moderator, :admin].each do |role|
  context "when the current user is a(n) #{role}" do
    let(:user) { create("confirmed_#{role}".to_sym) }
    # ... tests
  end
end
```

## Rules

- Use `frozen_string_literal: true` pragma.
- GraphQL query strings use `<<-GRAPHQL` heredoc (not `<<~GRAPHQL`).
- Variable names in the GraphQL string are camelCase; variable keys in the Ruby hash are snake_case.
- Use `let!` (bang) for records that must exist before the request (update/delete targets).
- Use `let` (no bang) for records created lazily (user, application, access_token).
- Check the mutation's `authorized?` method to determine which roles can perform the action. Typically: moderator+ for create/update, admin-only for delete.
- For complex models with associations, create associated records with factories and pass their IDs in variables.
