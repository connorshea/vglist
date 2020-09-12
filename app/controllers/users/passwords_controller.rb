# typed: true
# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
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
end
