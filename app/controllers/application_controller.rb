class ApplicationController < ActionController::Base
  include Pundit
  # Require a valid CSRF token, throw an exception if there isn't one.
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  # In devise-related pages, permit a username parameter.
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Make sure pundit is implemented on everything, except index pages since
  # those should be accessible without an authorization.
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  protected

  # Add username as an accepted key during sign up.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end
end
