module Types
  class BaseObject < GraphQL::Schema::Object
    include Pundit::Authorization

    connection_type_class(Types::BaseConnectionObject)

    # NOTE: Request-level authentication (logged in, not banned, has the
    # required OAuth scope) is enforced in GraphqlController#execute before the
    # schema runs. It deliberately does NOT live in a root `.authorized?`:
    # raising GraphQL::ExecutionError from the root type's `.authorized?`
    # crashes graphql-ruby, which dereferences a nil current_object while
    # building the error. Per-object authorization still lives in each
    # type's/mutation's own `.authorized?`.
  end
end
