# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Image fields (`coverUrl`, `avatarUrl`) return the storage service's URL for
  # a variant. In production that's a public R2 URL, but the Disk service
  # used in development and tests builds URLs from the current request's host.
  include ActiveStorage::SetCurrent

  # Authentication is optional here: `current_user` comes from the JWT if one
  # is sent, and the schema itself handles auth for individual queries and
  # mutations. This allows unauthenticated mutations like signIn and signUp
  # to work.
  #
  # Queries can also be sent as `GET /graphql?documentId=sha256:...`, which
  # Cloudflare can cache. See #persisted_query.
  def execute
    skip_authorization
    # Only cacheable GET responses are allowed into a shared cache, see below.
    no_store

    variables = parse_variables
    return if performed?

    operation_name = params[:operationName]

    if persisted_query_request?
      query = persisted_query(operation_name)
      return if performed?
    else
      query = params[:query]
      unless operation_allowed?(query, current_user)
        render_error("This GraphQL operation is not allowed. The vglist API only accepts operations sent by the vglist web app.", :bad_request)
        return
      end
    end

    name_sentry_transaction(operation_name)

    context = {
      current_user: current_user,
      client_ip: RackAttackConfig.client_ip(request),
      pundit: self
    }

    cache_key = PublicResponseCache.key_for(query, operation_name, variables, current_user)
    store_at_origin = cache_key && PublicResponseCache.store_at_origin?(operation_name)
    if store_at_origin && (cached = Rails.cache.read(cache_key))
      allow_shared_caching
      render json: cached
      return
    end

    result = VideoGameListSchema.execute(query.to_s, variables: variables, context: context, operation_name: operation_name)
    # Only successful responses are cached, so a timeout isn't served for minutes.
    if cache_key && result['errors'].blank?
      Rails.cache.write(cache_key, result.to_json, expires_in: PublicResponseCache::EXPIRES_IN) if store_at_origin
      allow_shared_caching
    end
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  protected

  # Reject requests from banned users with a GraphQL-shaped error.
  def reject_banned_users
    return unless current_user&.banned?

    render_error("The user that owns this token has been banned.", :forbidden)
  end

  private

  # Rails routes HEAD to the GET action, and HEAD should behave the same, just
  # without a body (e.g. `curl -I` when checking the cache headers).
  def persisted_query_request?
    request.get? || request.head?
  end

  def render_error(message, status, code: nil)
    error = { message: message }
    error[:extensions] = { code: code } if code
    render json: { data: nil, errors: [error] }, status: status
  end

  # The document for a GET request, which names a persisted document from the
  # operation allowlist instead of sending one, or nil after rendering an
  # error.
  #
  # GET requests are for signed-out queries that a CDN can cache, so:
  #
  # - Only allowlisted documents can be sent, and only by ID. This keeps URLs
  #   (and cache keys) short and stable, and nothing outside the allowlist
  #   runs over GET, even for admins.
  # - Mutations are rejected, as the GraphQL over HTTP spec requires.
  # - Requests with an `Authorization` header are rejected, so the origin
  #   never produces a per-user response at a URL a CDN might share between
  #   visitors. Cloudflare doesn't key its cache on headers, so a signed-in
  #   user's GET would be answered with whatever the URL last returned.
  def persisted_query(operation_name)
    if request.headers['Authorization'].present?
      render_error("GET requests to /graphql can't be authenticated. Send signed-in requests as POST.", :bad_request)
      return
    end

    if params[:query].present?
      render_error("GET requests to /graphql must send a documentId instead of a query.", :bad_request)
      return
    end

    query = OperationAllowlist.persisted_document(params[:documentId])
    # 404 tells the SPA to retry over POST. That also covers the API being
    # behind the SPA during a deploy, when it doesn't know a new document's ID
    # yet.
    if query.nil? || OperationAllowlist.operations[operation_name] != query
      render_error("Unknown persisted document.", :not_found, code: 'PERSISTED_DOCUMENT_NOT_FOUND')
      return
    end

    unless query_operation?(query, operation_name)
      response.headers['Allow'] = 'POST'
      render_error("Mutations can only be sent as POST requests.", :method_not_allowed)
      return
    end

    query
  end

  def query_operation?(query, operation_name)
    operation = GraphQL.parse(query).definitions.find do |definition|
      definition.is_a?(GraphQL::Language::Nodes::OperationDefinition) && definition.name == operation_name
    end
    operation&.operation_type == 'query'
  end

  # Let browsers and Cloudflare cache this response. Only GET responses
  # qualify: Cloudflare never caches POST, and every other response keeps
  # `no-store`.
  #
  # Browsers keep it for a minute and Cloudflare for five, then Cloudflare
  # serves the stale copy for up to ten more while it refetches in the
  # background. With PublicResponseCache's own five minutes at the origin, a
  # change can take up to ~20 minutes to reach signed-out visitors.
  def allow_shared_caching
    return unless persisted_query_request?

    expires_in 1.minute, public: true, stale_while_revalidate: 10.minutes, 's-maxage': 5.minutes.to_i
    # Rack::Cors only adds this when the request has a matching Origin, but a
    # cached response is shared with every visitor. If the request that filled
    # the cache had no Origin header (e.g. curl), browsers would reject the
    # cached copy, so always include it.
    response.headers['Access-Control-Allow-Origin'] = ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
  end

  # Every request goes to /graphql, so name the Sentry transaction after the
  # operation instead, e.g. "GraphQL GetGame". Otherwise every trace would be
  # grouped under GraphqlController#execute. operationName is whatever the
  # client sent, so only names from the SPA's operation allowlist are used.
  def name_sentry_transaction(operation_name)
    return unless OperationAllowlist.operations.key?(operation_name)

    Sentry.configure_scope { |scope| scope.set_transaction_name("GraphQL #{operation_name}") }
  end

  # Only operations the SPA sends are executed, see OperationAllowlist. Admins
  # may send anything, which is useful for debugging in production.
  def operation_allowed?(query, user)
    return true unless OperationAllowlist.enabled?
    return true if user&.admin?

    OperationAllowlist.allowed?(query)
  end

  # The request's variables as a hash, or nil after rendering a 400 for
  # variables that aren't a JSON object, so a malformed GET URL can't cause a
  # 500.
  def parse_variables
    ensure_hash(params[:variables])
  rescue JSON::ParserError, ArgumentError
    render_error("variables must be a JSON object.", :bad_request)
    nil
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
