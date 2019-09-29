# typed: false
class GraphqlController < ApplicationController
  # Allow bypassing doorkeeper_authorize! if the user is logged in, to
  # enable GraphiQL.
  before_action :doorkeeper_authorize!, if: -> { current_user.nil? }
  # Disable CSRF protection for GraphQL because we don't want to have CSRF
  # protection on our API endpoint. The point is to let anyone send requests
  # to the API.
  skip_before_action :verify_authenticity_token

  def execute
    # TODO: Authenticate things properly.
    skip_authorization

    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user || doorkeeper_user,
      pundit: self
    }
    result = VideoGameListSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
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
end
