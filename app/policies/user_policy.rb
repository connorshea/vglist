# typed: true
class UserPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :current_user, :user

  sig { params(current_user: T.nilable(User), user: T.nilable(User)).void }
  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T.nilable(T::Boolean)) }
  def show?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def update?
    user_is_current_user?
  end

  # Rules for updating roles:
  # - The user updating the role must be an admin.
  # - The user can't update their own role.
  sig { returns(T.nilable(T::Boolean)) }
  def update_role?
    current_user&.admin? && user != current_user
  end

  sig { returns(T.nilable(T::Boolean)) }
  def add_game_to_library?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def remove_game_from_library?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def remove_avatar?
    user_is_current_user? || current_user&.admin? || current_user&.moderator?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def steam_import?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def connect_steam?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def disconnect_steam?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def reset_game_library?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def statistics?
    user_profile_is_visible?
  end

  # The authorize method is called once for each user in the compare page, so
  # we only need to worry about checking one user's visibility at a time.
  sig { returns(T.nilable(T::Boolean)) }
  def compare?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def activity?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def favorites?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def following?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def followers?
    user_profile_is_visible?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def user_is_current_user?
    current_user && user == current_user
  end

  sig { returns(T.nilable(T::Boolean)) }
  def user_profile_is_visible?
    user&.public_account? || user_is_current_user? || current_user&.admin?
  end
end
