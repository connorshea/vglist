# typed: true
class AdminController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy
  end
end
