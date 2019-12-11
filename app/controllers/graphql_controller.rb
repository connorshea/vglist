# typed: false
class GraphqlController < ApplicationController
  # Skip bullet on GraphQL queries to avoid errors.
  around_action :skip_bullet, if: -> { defined?(Bullet) }

  # Allow bypassing authorization if the user is logged in, to
  # enable GraphiQL.
  before_action :authorize_api_user, if: -> { current_user.nil? && user_using_oauth? }

  # Disable CSRF protection for GraphQL because we don't want to have CSRF
  # protection on our API endpoint. The point is to let anyone send requests
  # to the API.
  skip_before_action :verify_authenticity_token

  # Use SimpleTokenAuthentication if the user's request doesn't have an OAuth token.
  acts_as_token_authentication_handler_for User, if: ->(controller) { !controller.user_using_oauth? }

  def execute
    skip_authorization

    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user || api_user || doorkeeper_user,
      pundit: self,
      doorkeeper_scopes: doorkeeper_token&.scopes&.to_a,
      graphiql_override: false,
      token_auth: !user_using_oauth?
    }

    # Set graphiql_override to true if in development mode and the request
    # has the GraphiQL Request header. This is used to allow GraphiQL
    # requests to skip the Doorkeeper token checks.
    context[:graphiql_override] = true if Rails.env.development? && request.headers['X-GraphiQL-Request'] == 'true'

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
    @doorkeeper_user ||= User.find(doorkeeper_token[:resource_owner_id])
  end

  def api_user
    User.find_by(authentication_token: request.headers['X-User-Token'])
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

  # TODO: Add handling for 'normal' API tokens here.
  def authorize_api_user
    doorkeeper_authorize!
  end

  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = previous_value
  end
end
