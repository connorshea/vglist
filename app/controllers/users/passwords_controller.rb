# typed: false
# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  invisible_captcha only: [:create, :update], on_spam: :spam_callback, honeypot: :honey

  # GET /resource/password/new
  def new
    skip_authorization
    super
  end

  # POST /resource/password
  def create
    skip_authorization
    super
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    skip_authorization
    super
  end

  # PUT /resource/password
  def update
    skip_authorization
    super
  end

  private

  def spam_callback
    redirect_to root_path
  end

  # Disable PaperTrail to prevent weird errors with Devise that are caused by
  # providing the PaperTrail metadata in ApplicationController.
  def paper_trail_enabled_for_controller
    false
  end
end
