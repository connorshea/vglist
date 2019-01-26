class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def index?
    true
  end

  def show?
    true
  end

  def update?
    current_user && @user = @current_user
  end

  def update_role?
    current_user&.admin?
  end
end
