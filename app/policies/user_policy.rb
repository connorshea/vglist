# typed: strict
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
    user_profile_is_visible?
  end

  def update?
    user_is_current_user?
  end

  def search?
    true
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

  def reset_token?
    user_is_current_user?
  end

  def reset_game_library?
    user_is_current_user?
  end

  def statistics?
    user_profile_is_visible?
  end

  # The authorize method is called once for each user in the compare page, so
  # we only need to worry about checking one user's visibility at a time.

  def compare?
    user_profile_is_visible?
  end

  def activity?
    user_profile_is_visible?
  end

  def favorites?
    user_profile_is_visible?
  end

  def following?
    user_profile_is_visible?
  end

  def followers?
    user_profile_is_visible?
  end

  def ban?
    # Let admins ban any users, and allow moderators to ban any users that
    # aren't moderators or admins. Admins can ban other admins, but I'm
    # sure that won't ever cause any problems. Also, users shouldn't be
    # able to ban themselves.
    (current_user&.admin? || (current_user&.moderator? && !user&.admin? && !user&.moderator?)) && !user_is_current_user?
  end

  def unban?
    # Let admins and moderators unban any users, except themselves.
    (current_user&.admin? || current_user&.moderator?) && !user_is_current_user?
  end

  def destroy?
    # Only the user in question can destroy themselves.
    user_is_current_user?
  end

  private

  def user_is_current_user?
    current_user && user == current_user
  end

  # User profiles are always visible to their own user and to admins. They are
  # not visible to moderators or normal users if they're private or if they've
  # been banned.

  def user_profile_is_visible?
    (user&.public_account? && !user&.banned?) || user_is_current_user? || current_user&.admin?
  end
end
