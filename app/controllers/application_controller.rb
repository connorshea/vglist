# typed: false
class ApplicationController < ActionController::Base
  include Pundit
  # Require a valid CSRF token, throw an exception if there isn't one.
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  # In devise-related pages, permit a username parameter.
  before_action :configure_permitted_parameters, if: :devise_controller?
  # If the user has been banned, sign them out.
  before_action :sign_out_banned_users
  # Send context with error messages to Sentry.
  before_action :set_raven_context

  # Make sure pundit is implemented on everything, except index pages since
  # those should be accessible without an authorization.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  add_flash_types :success, :error

  protected

  # Sign out the current user if they've been banned.
  def sign_out_banned_users
    return unless current_user&.banned?

    sign_out
    redirect_to root_path
  end

  # Add username as an accepted key during sign up.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  # Send user ID, params, and request URL to Sentry on-error.
  def set_raven_context
    Raven.user_context(id: current_user&.id, username: current_user&.username)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
