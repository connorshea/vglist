# frozen_string_literal: true

# Reports a GraphQL request that ran out of time to Sentry. Both kinds of
# timeout come back to the client as a GraphQL error, never as an exception,
# so without this they'd never show up in Sentry:
#
# - :statement_timeout, a single SQL statement cancelled by the Postgres
#   statement timeout (see GraphqlController#with_statement_timeout).
# - :query_timeout, the whole query running past QueryTimeout's limit.
#
# Events are grouped by timeout kind and operation, so each slow operation
# gets one Sentry issue. At most one event is sent per request, since one
# slow request can cancel several statements.
module GraphqlTimeoutReport
  # @param query [GraphQL::Query, nil] the query that timed out
  # @param kind [Symbol] :statement_timeout or :query_timeout
  # @param message [String] what timed out, e.g. "Timeout on Query.game"
  # @param exception [Exception, nil] reported with its backtrace if given
  def self.capture(query, kind:, message:, exception: nil)
    return if query.nil? || query.context[:graphql_timeout_reported]

    query.context[:graphql_timeout_reported] = true
    operation = query.selected_operation_name || 'anonymous'

    Sentry.with_scope do |scope|
      scope.set_tags(graphql_operation: operation, graphql_timeout: kind.to_s)
      scope.set_context('graphql_timeout', { operation: operation, kind: kind.to_s, message: message })
      scope.set_fingerprint(['graphql-timeout', kind.to_s, operation])

      if exception
        Sentry.capture_exception(exception)
      else
        Sentry.capture_message("GraphQL #{operation} timed out: #{message}", level: :warning)
      end
    end
  end
end
