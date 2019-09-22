# typed: strict
class VideoGameListSchema < GraphQL::Schema
  extend T::Sig

  mutation(Types::MutationType)
  query(Types::QueryType)

  # Configure max_depth to prevent crazy queries.
  # max_complexity is disabled for now to allow the GraphiQL documentation
  # panel to work. max_depth is set to 13 as that's what's requires for
  # introspection to work, which is what's used for the documentation panel.
  max_depth 13
  # max_complexity 50

  # Override this hook to handle cases when `authorized?` returns false for an object.
  sig { params(error: GraphQL::UnauthorizedError).void }
  def self.unauthorized_object(error)
    # Add a top-level error to the response instead of returning nil.
    raise GraphQL::ExecutionError, "An object of type #{error.type.graphql_name} was hidden due to permissions"
  end

  # Override this hook to handle cases when `authorized?` returns false for a field.
  sig { params(error: GraphQL::UnauthorizedFieldError).void }
  def self.unauthorized_field(error)
    # Add a top-level error to the response instead of returning nil.
    raise GraphQL::ExecutionError, "The field #{error.field.graphql_name} on an object of type #{error.type.graphql_name} was hidden due to permissions"
  end
end
