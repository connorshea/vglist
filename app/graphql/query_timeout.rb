# frozen_string_literal: true

# GraphQL::Schema::Timeout, but only for queries.
#
# The timeout doesn't interrupt a resolver that's already running, it only
# stops fields that start after the deadline. For a mutation that means the
# work is done and committed, then the payload fields come back null with a
# timeout error, so the client reports a failure for a change that succeeded.
# Slow mutations (Steam library imports, deleting a user, merging games) are
# still bounded per statement by the Postgres statement timeout set in
# GraphqlController.
class QueryTimeout < GraphQL::Schema::Timeout
  def max_seconds(query)
    query.mutation? ? false : super
  end

  # Called once per query, on the first field that starts after the deadline.
  def handle_timeout(error, query)
    GraphqlTimeoutReport.capture(query, kind: :query_timeout, message: error.message)
  end
end
