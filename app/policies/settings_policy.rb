# typed: strong
class SettingsPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :current_user, :user

  sig { params(current_user: T.nilable(User), user: T.nilable(User)).void }
  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  sig { returns(T.nilable(T::Boolean)) }
  def profile?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def account?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def import?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def export?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def export_as_json?
    user_is_current_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def api_token?
    user_is_current_user?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def user_is_current_user?
    current_user && user == current_user
  end
end
