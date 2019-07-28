# typed: true
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

  def connections?
    user_is_current_user?
  end

  private

  def user_is_current_user?
    current_user && user == current_user
  end
end
