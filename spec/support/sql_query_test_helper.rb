# frozen_string_literal: true

# Helpers for measuring the SQL run by a block, so a spec can assert that a
# request preloads its associations rather than running a query per record.
#
# Schema lookups, transaction statements and query cache hits never represent a
# database round trip worth measuring, so they're all ignored.
module SqlQueryTestHelper
  IGNORED_QUERY_NAMES = /SCHEMA|TRANSACTION|CACHE/
  TRANSACTION_STATEMENTS = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i

  # The SQL statements run while the block executes.
  #
  # @return [Array<String>]
  def queries_run
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      sql = payload[:sql].to_s
      queries << sql unless payload[:name].to_s.match?(IGNORED_QUERY_NAMES) || sql.match?(TRANSACTION_STATEMENTS)
    end
    yield
    return queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  # The number of SQL queries run while the block executes.
  #
  # @return [Integer]
  def query_count(&)
    return queries_run(&).count
  end

  # The tables touched while running a block, so that a query can be checked
  # for preloading associations it never asked for.
  #
  # @return [Array<String>]
  def tables_queried(&)
    return queries_run(&).filter_map { |sql| sql[/FROM "([^"]+)"/, 1] }.uniq
  end
end
