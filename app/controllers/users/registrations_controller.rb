# typed: false
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    skip_authorization
    super
  end

  # POST /resource
  def create
    skip_authorization
    super
  end

  # GET /resource/edit
  def edit
    skip_authorization
    redirect_to settings_account_path
  end

  # Based on the code in the devise repo.
  # https://github.com/plataformatec/devise/blob/07f2712a22aa05b8da61c85307b80a3bd2ed6c4c/app/controllers/devise/registrations_controller.rb#L43-L62
  # Fixes form submit errors redirecting to /users instead of settings_account_path.
  # https://github.com/plataformatec/devise/issues/4573
  # TODO: Figure out how to get the devise error messages displayed.
  def update
    skip_authorization
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      flash[:error] = "Unable to update account info."
      redirect_to settings_account_path
    end
  end

  # DELETE /resource
  def destroy
    skip_authorization
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    skip_authorization
    super
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end
end
