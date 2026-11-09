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

  # Use GraphQL-Ruby's fixed complexity calculation (the default in a future
  # version). When the same response key is selected more than once, e.g.
  # through fragments on different types, it scores the most expensive
  # selection rather than whichever came last, so it can only be higher than
  # the legacy calculation. Every operation in the allowlist scores the same
  # either way.
  complexity_cost_calculation_mode :future

  # Prevent alias-batching the unauthenticated auth mutations into a single
  # request (credential brute force / email bombing).
  query_analyzer Analyzers::AuthMutationLimitAnalyzer

  # Negative `first:`/`last:` would lower a query's complexity score.
  query_analyzer Analyzers::NonNegativePaginationAnalyzer

  default_max_page_size 100
  default_page_size 30

  # Stop resolving fields once a query has run for this long. Fields that
  # haven't resolved yet return null with an error. Mutations are exempt, see
  # QueryTimeout. This complements the Postgres statement timeout set
  # per connection in config/database.yml, which catches a single slow statement, whereas this
  # catches many fast ones.
  use QueryTimeout, max_seconds: 30

  # Batches `Game.ownerCount` into one query per response.
  lazy_resolve(LazyOwnerCount, :value)
  # Batches the `coverGames` of series, genres, platforms, companies and engines.
  lazy_resolve(LazyCoverGames, :value)
  # Batches the second user's purchases in a library comparison.
  lazy_resolve(LazyGamePurchase, :value)

  # A statement cancelled by the statement timeout (see config/database.yml).
  rescue_from(ActiveRecord::QueryCanceled) do |err, _obj, _args, ctx, field|
    GraphqlTimeoutReport.capture(
      ctx&.query,
      kind: :statement_timeout,
      message: "Statement cancelled#{" in #{field.path}" if field}",
      exception: err
    )
    raise GraphQL::ExecutionError, "This request took too long and was cancelled."
  end

  # Return a valid response when an ActiveRecord record can't be found.
  rescue_from(ActiveRecord::RecordNotFound) do |err, _obj, _args, _ctx, _field|
    # Raise a graphql-friendly error with the error message from the exception.
    raise GraphQL::ExecutionError, "Record not found: #{err.message}"
  end
end
