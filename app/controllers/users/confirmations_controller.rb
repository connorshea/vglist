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
end
