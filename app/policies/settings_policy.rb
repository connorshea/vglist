class SettingsPolicy < ApplicationPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def profile?
    current_user && user == current_user
  end

  def account?
    current_user && user == current_user
  end

  def connections?
    current_user && user == current_user
  end
end
