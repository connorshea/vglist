# typed: false
class GraphqlController < ApplicationController
  # If the user hasn't provided any token, return a specific error message.
  before_action :handle_user_not_logged_in, if: -> { !current_user && !user_using_oauth? && !request.headers.key?('X-User-Email') }

  # Authenticate with Doorkeeper if there's no X-User-Email header.
  before_action :authorize_doorkeeper_user, if: -> { !request.headers.key?('X-User-Email') && user_using_oauth? }

  # Authenticate with a user's authorization token if they're not using OAuth.
  before_action :authorize_token_user, if: -> { !user_using_oauth? }

  # Disable CSRF protection for GraphQL because we don't want to have CSRF
  # protection on our API endpoint. The point is to let anyone send requests
  # to the API.
  skip_before_action :verify_authenticity_token

  def execute
    skip_authorization

    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    graphql_current_user = api_user || doorkeeper_user
    if graphql_current_user.nil?
      handle_user_not_logged_in
      return
    end

    context = {
      current_user: graphql_current_user,
      pundit: self,
      doorkeeper_scopes: doorkeeper_token&.scopes&.to_a,
      token_auth: !user_using_oauth?
    }

    result = VideoGameListSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  protected

  # Check whether the user is using OAuth based on whether an Authorization header is included.
  def user_using_oauth?
    request.headers.key?('Authorization')
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
    return if doorkeeper_token.nil?

    @doorkeeper_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  def api_user
    User.find_by(email: request.headers['X-User-Email'])
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

  def authorize_doorkeeper_user
    doorkeeper_authorize!
  end

  def authorize_token_user
    handle_user_not_logged_in unless api_user&.verify_api_token!(request.headers['X-User-Token'])
  end

  def handle_user_not_logged_in
    render json: { error: { message: 'You must provide a valid email and token to use the GraphQL API.' } }, status: :unauthorized
  end
end
