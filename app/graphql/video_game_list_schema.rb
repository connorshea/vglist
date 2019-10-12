# typed: strict
class VideoGameListSchema < GraphQL::Schema
  extend T::Sig

  # Use new error handling and interpreter.
  use GraphQL::Execution::Interpreter
  use GraphQL::Analysis::AST
  use GraphQL::Execution::Errors
  use GraphQL::Pagination::Connections

  mutation(Types::MutationType)
  query(Types::QueryType)

  # Configure max_depth to prevent crazy queries.
  # max_complexity is disabled for now to allow the GraphiQL documentation
  # panel to work. max_depth is set to 13 as that's what's requires for
  # introspection to work, which is what's used for the documentation panel.
  max_depth 13
  # max_complexity 50

  default_max_page_size 30

  # Return a valid response when an ActiveRecord record can't be found.
  rescue_from(ActiveRecord::RecordNotFound) do |_err, _obj, _args, _ctx, field|
    # Raise a graphql-friendly error with a custom message
    raise GraphQL::ExecutionError, "#{field.type.unwrap.graphql_name} not found"
  end
end
