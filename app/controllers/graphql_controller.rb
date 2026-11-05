# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Image fields (`coverUrl`, `avatarUrl`) return the storage service's URL for
  # a variant. In production that's a public Spaces URL, but the Disk service
  # used in development and tests builds URLs from the current request's host.
  include ActiveStorage::SetCurrent

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

    context = {
      current_user: current_user,
      pundit: self
    }

    result = VideoGameListSchema.execute(query.to_s, variables: variables, context: context, operation_name: operation_name)
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
