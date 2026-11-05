class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Images are rendered with the storage service's URL for each attachment or
  # variant. In production that's a public URL, but the Disk service used in
  # development and tests builds URLs from the current request's host.
  include ActiveStorage::SetCurrent

  # Require a valid CSRF token, throw an exception if there isn't one.
  protect_from_forgery with: :exception, unless: -> {
    request.format.json?
  }

  # In devise-related pages, permit a username parameter.
  before_action :configure_permitted_parameters, if: :devise_controller?
  # If the user has been banned, sign them out.
  before_action :sign_out_banned_users
  # Send context with error messages to Sentry.
  before_action :set_sentry_context
  # Set PaperTrail whodunnit to the current user.
  before_action :set_paper_trail_whodunnit

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

  # Send user id and username to Sentry on-error.
  def set_sentry_context
    Sentry.set_user(id: current_user&.id, username: current_user&.username)
  end

  # Set whodunnit to the user's username.
  def user_for_paper_trail
    current_user&.username
  end

  # Set whodunnit_id to the user's numeric ID.
  def info_for_paper_trail
    { whodunnit_id: current_user&.id }
  end
end
