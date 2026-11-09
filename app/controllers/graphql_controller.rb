# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Image fields (`coverUrl`, `avatarUrl`) return the storage service's URL for
  # a variant. In production that's a public R2 URL, but the Disk service
  # used in development and tests builds URLs from the current request's host.
  include ActiveStorage::SetCurrent

  around_action :with_statement_timeout, only: :execute

  # Authentication is optional here: `current_user` comes from the JWT if one
  # is sent, and the schema itself handles auth for individual queries and
  # mutations. This allows unauthenticated mutations like signIn and signUp
  # to work.
  def execute
    skip_authorization

    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    unless operation_allowed?(query, current_user)
      render json: {
        data: nil,
        errors: [{ message: "This GraphQL operation is not allowed. The vglist API only accepts operations sent by the vglist web app." }]
      }, status: :bad_request
      return
    end

    name_sentry_transaction(operation_name)

    context = {
      current_user: current_user,
      client_ip: RackAttackConfig.client_ip(request),
      pundit: self
    }

    cache_key = PublicResponseCache.key_for(query, operation_name, variables, current_user)
    if cache_key && (cached = Rails.cache.read(cache_key))
      render json: cached
      return
    end

    result = VideoGameListSchema.execute(query.to_s, variables: variables, context: context, operation_name: operation_name)
    # Only successful responses are cached, so a timeout isn't served for minutes.
    Rails.cache.write(cache_key, result.to_json, expires_in: PublicResponseCache::EXPIRES_IN) if cache_key && result['errors'].blank?
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  protected

  # Reject requests from banned users with a GraphQL-shaped error.
  def reject_banned_users
    return unless current_user&.banned?

    render json: {
      data: nil,
      errors: [{ message: "The user that owns this token has been banned." }]
    }, status: :forbidden
  end

  private

  # Every request is POST /graphql, so name the Sentry transaction after the
  # operation instead, e.g. "GraphQL GetGame". Otherwise every trace would be
  # grouped under GraphqlController#execute. operationName is whatever the
  # client sent, so only names from the SPA's operation allowlist are used.
  def name_sentry_transaction(operation_name)
    return unless OperationAllowlist.operations.key?(operation_name)

    Sentry.configure_scope { |scope| scope.set_transaction_name("GraphQL #{operation_name}") }
  end

  # Cap how long any single SQL statement may run while serving a GraphQL
  # request, so one expensive query can't hold a database connection
  # indefinitely. Postgres cancels the statement and VideoGameListSchema turns
  # the error into a GraphQL error. Override with GRAPHQL_STATEMENT_TIMEOUT
  # (a Postgres duration, e.g. "15s").
  def with_statement_timeout
    connection = ActiveRecord::Base.lease_connection
    timeout = ENV.fetch('GRAPHQL_STATEMENT_TIMEOUT', '10s')
    connection.execute("SET statement_timeout = #{connection.quote(timeout)}")
    yield
  ensure
    # Connections are pooled and reused by other requests and jobs, so put the
    # server default back. The SET ran outside any transaction, so nothing rolls
    # it back for us. If the RESET fails, drop the connection instead: the next
    # checkout reconnects with a fresh session and the default timeout.
    begin
      connection&.execute('RESET statement_timeout')
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.warn("Could not reset statement_timeout, disconnecting: #{e.message}")
      connection.disconnect!
    end
  end

  # Only operations the SPA sends are executed, see OperationAllowlist. Admins
  # may send anything, which is useful for debugging in production.
  def operation_allowed?(query, user)
    return true unless OperationAllowlist.enabled?
    return true if user&.admin?

    OperationAllowlist.allowed?(query)
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(err)
    logger.error err.message
    logger.error err.backtrace.join("\n")

    render json: { error: { message: err.message, backtrace: err.backtrace }, data: {} }, status: :internal_server_error
  end
end
