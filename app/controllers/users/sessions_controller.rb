# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  invisible_captcha only: [:create, :update], scope: :user, on_spam: :spam_callback, honeypot: :honey

  # GET /resource/sign_in
  def new
    skip_authorization
    super
  end

  # POST /resource/sign_in
  def create
    skip_authorization
    super
  end

  # DELETE /resource/sign_out
  def destroy
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
