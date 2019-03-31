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
    current_user && user == current_user
  end

  # Rules for updating roles:
  # - The user updating the role must be an admin.
  # - The user can't update their own role.
  def update_role?
    current_user&.admin? && user != current_user
  end

  def add_game_to_library?
    current_user && user == current_user
  end

  def remove_game_from_library?
    current_user && user == current_user
  end

  def remove_avatar?
    current_user && user == current_user
  end

  def steam?
    current_user
  end
end
