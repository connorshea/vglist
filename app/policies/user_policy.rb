# typed: true
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
    user_is_current_user?
  end

  # Rules for updating roles:
  # - The user updating the role must be an admin.
  # - The user can't update their own role.
  def update_role?
    current_user&.admin? && user != current_user
  end

  def add_game_to_library?
    user_is_current_user?
  end

  def remove_game_from_library?
    user_is_current_user?
  end

  def remove_avatar?
    user_is_current_user? || current_user&.admin? || current_user&.moderator?
  end

  def steam_import?
    user_is_current_user?
  end

  def connect_steam?
    user_is_current_user?
  end

  def disconnect_steam?
    user_is_current_user?
  end

  def reset_game_library?
    user_is_current_user?
  end

  def statistics?
    true
  end

  def compare?
    true
  end

  private

  def user_is_current_user?
    current_user && user == current_user
  end
end
