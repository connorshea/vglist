# typed: false
# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
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
end
