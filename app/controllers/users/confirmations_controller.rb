# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # POST /resource/confirmation
  def create
    skip_authorization
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    if successfully_sent?(resource)
      render json: { message: "Confirmation instructions sent." }
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    skip_authorization
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    if resource.errors.empty?
      # Redirect to the frontend app's login page after confirmation
      redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/login?confirmed=true", allow_other_host: true
    else
      redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/login?confirmation_error=true", allow_other_host: true
    end
  end

  private

  # Disable PaperTrail to prevent weird errors with Devise that are caused by
  # providing the PaperTrail metadata in ApplicationController.
  def paper_trail_enabled_for_controller
    false
  end
end
