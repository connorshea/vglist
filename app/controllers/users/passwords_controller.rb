# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/edit?reset_password_token=abcdef
  # Redirect to the frontend app's password reset form with the token.
  def edit
    skip_authorization
    frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
    redirect_to "#{frontend_url}/password/reset/confirm?reset_password_token=#{params[:reset_password_token]}", allow_other_host: true
  end

  # POST /resource/password (request password reset email)
  def create
    skip_authorization
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    if successfully_sent?(resource)
      render json: { message: "Password reset instructions sent." }
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PUT /resource/password (reset password with token)
  def update
    skip_authorization
    self.resource = resource_class.reset_password_by_token(resource_params)
    if resource.errors.empty?
      render json: { message: "Password has been reset successfully." }
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  # Disable PaperTrail to prevent weird errors with Devise that are caused by
  # providing the PaperTrail metadata in ApplicationController.
  def paper_trail_enabled_for_controller
    false
  end
end
