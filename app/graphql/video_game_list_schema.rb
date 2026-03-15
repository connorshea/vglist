class VideoGameListSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Introspection (used by the GraphiQL documentation panel) requires
  # a depth of at least 13, but we don't really care for now.
  max_depth 10

  # Default complexity limit for third-party API consumers.
  # First-party queries bypass this via the controller (see GraphqlController#execute).
  max_complexity 500

  default_max_page_size 100
  default_page_size 30

  # Return a valid response when an ActiveRecord record can't be found.
  rescue_from(ActiveRecord::RecordNotFound) do |err, _obj, _args, _ctx, _field|
    # Raise a graphql-friendly error with the error message from the exception.
    raise GraphQL::ExecutionError, "Record not found: #{err.message}"
  end
end
