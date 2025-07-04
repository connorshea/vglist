class SettingsPolicy < ApplicationPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def profile?
    user_is_current_user?
  end

  def account?
    user_is_current_user?
  end

  def import?
    user_is_current_user?
  end

  def export?
    user_is_current_user?
  end

  def export_as_json?
    user_is_current_user?
  end

  def api_token?
    user_is_current_user?
  end

  private

  def user_is_current_user?
    current_user && user == current_user
  end
end
