# typed: true
# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  def new
    skip_authorization
    super
  end

  # POST /resource/confirmation
  def create
    skip_authorization
    super
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    skip_authorization
    super
  end

  private

  # Disable PaperTrail to prevent weird errors with Devise that are caused by
  # providing the PaperTrail metadata in ApplicationController.
  def paper_trail_enabled_for_controller
    false
  end
end
