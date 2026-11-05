# frozen_string_literal: true

class VideoGameListSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Introspection (used by the GraphiQL documentation panel) requires
  # a depth of at least 13, but we don't really care for now.
  max_depth 10

  # Applies to every request, signed in or not. It's set just above what the
  # SPA's own operations need at the page sizes it requests (checked by
  # spec/requests/graphql/complexity_spec.rb), which mostly matters for
  # requests that skip the operation allowlist (admins, or with the allowlist
  # turned off). Short association lists are scored as ~10 records, see
  # Types::BaseField::ShortListComplexity.
  max_complexity 5000

  # Prevent alias-batching the unauthenticated auth mutations into a single
  # request (credential brute force / email bombing).
  query_analyzer Analyzers::AuthMutationLimitAnalyzer

  # Negative `first:`/`last:` would lower a query's complexity score.
  query_analyzer Analyzers::NonNegativePaginationAnalyzer

  default_max_page_size 100
  default_page_size 30

  # Stop resolving fields once a query has run for this long. Fields that
  # haven't resolved yet return null with an error. Mutations are exempt, see
  # QueryTimeout. This complements the Postgres statement timeout set in
  # GraphqlController, which catches a single slow statement, whereas this
  # catches many fast ones.
  use QueryTimeout, max_seconds: 10

  # A statement cancelled by the statement timeout (see GraphqlController).
  rescue_from(ActiveRecord::QueryCanceled) do |_err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError, "This request took too long and was cancelled."
  end

  # Return a valid response when an ActiveRecord record can't be found.
  rescue_from(ActiveRecord::RecordNotFound) do |err, _obj, _args, _ctx, _field|
    # Raise a graphql-friendly error with the error message from the exception.
    raise GraphQL::ExecutionError, "Record not found: #{err.message}"
  end
end
