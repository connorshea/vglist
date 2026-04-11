# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Skip authentication for GraphQL — the schema itself handles auth for
  # individual queries/mutations. This allows unauthenticated mutations like
  # signIn and signUp to work.
  before_action :authenticate_user_if_possible

  def execute
    skip_authorization

    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    graphql_current_user = @jwt_user || @api_token_user || doorkeeper_user

    context = {
      current_user: graphql_current_user,
      pundit: self,
      doorkeeper_scopes: doorkeeper_token&.scopes&.to_a,
      token_auth: !user_using_oauth?,
      first_party: first_party?
    }

    # Skip complexity limit for first-party queries (the SPA may need
    # higher complexity for pages like the activity feed).
    complexity_limit = first_party? ? nil : 500

    result = VideoGameListSchema.execute(query.to_s, variables: variables, context: context, operation_name: operation_name, max_complexity: complexity_limit)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  protected

  # Check whether the user is using OAuth based on whether a Doorkeeper token exists.
  def user_using_oauth?
    return false unless request.headers.key?('Authorization')

    # If the token is a JWT (contains dots), it's not OAuth
    auth_header = request.headers['Authorization']
    token = auth_header&.sub(/^Bearer\s+/i, '')
    return false if token&.count('.') == 2

    true
  end

  # Check whether the user is using JWT authentication.
  def user_using_jwt?
    return false unless request.headers.key?('Authorization')

    auth_header = request.headers['Authorization']
    token = auth_header&.sub(/^Bearer\s+/i, '')
    token&.count('.') == 2
  end

  private

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

  # Define doorkeeper_user based on the doorkeeper token because Doorkeeper
  # token-based requests don't have a current_user variable.
  def doorkeeper_user
    return @doorkeeper_user if defined?(@doorkeeper_user)
    return if doorkeeper_token.nil?

    user = User.find_by(id: doorkeeper_token[:resource_owner_id])
    @doorkeeper_user = user&.banned? ? nil : user
  end

  # Check whether the request is from a first-party client.
  def first_party?
    # Only trust JWT auth if the token was actually validated successfully.
    # Checking user_using_jwt? alone is not enough — an attacker could send
    # a malformed token (e.g. "a.b.c") that looks like a JWT but fails
    # decoding, bypassing complexity limits without authenticating.
    return true if @jwt_user.present?

    return false if doorkeeper_token.nil? || doorkeeper_token.application_id.nil?

    # Just block it in production for now to prevent malicious usage of the API,
    # but still allow local development.
    # TODO: MAKE SURE TO UNDO THIS BEFORE PRODUCTION RELEASE
    return false if Rails.env.production?

    true
  end

  # Handle doorkeeper's unauthorized errors so they return valid JSON.
  def doorkeeper_unauthorized_render_options(error: nil)
    {
      json: {
        data: nil,
        errors: [
          {
            message: "You are not authorized to perform this action."
          },
          {
            message: error.description
          }
        ]
      }
    }
  end

  # Attempt to authenticate the user from various methods, but don't block
  # the request if no auth is provided (some mutations like signIn/signUp
  # are allowed without authentication).
  def authenticate_user_if_possible
    if user_using_jwt?
      token = request.headers['Authorization']&.sub(/^Bearer\s+/i, '')
      user = JwtService.decode_and_verify(token)
      if user&.banned?
        render json: {
          data: nil,
          errors: [{ message: "The user that owns this token has been banned." }]
        }, status: :forbidden
        return
      end
      @jwt_user = user
    elsif user_using_oauth?
      doorkeeper_authorize!
      # Eagerly resolve the Doorkeeper user so we can check banned status
      # and cache the result for doorkeeper_user (avoids a duplicate query).
      if doorkeeper_token.present?
        user = User.find_by(id: doorkeeper_token[:resource_owner_id])
        if user&.banned?
          @doorkeeper_user = nil
          render json: {
            data: nil,
            errors: [{ message: "The user that owns this token has been banned." }]
          }, status: :forbidden
          return
        end
        @doorkeeper_user = user
      end
    elsif request.headers.key?('X-User-Email') && request.headers.key?('X-User-Token')
      # Token auth — only authenticate if both email and token are provided and valid
      user = User.find_by(email: request.headers['X-User-Email'])
      @api_token_user = user if user&.verify_api_token!(request.headers['X-User-Token']) && !user.banned?
    end
  end
end
