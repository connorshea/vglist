# typed: false
class SettingsPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :current_user, :user

  sig { params(current_user: User, user: User).void }
  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  sig { returns(T::Boolean) }
  def profile?
    user_is_current_user?
  end

  sig { returns(T::Boolean) }
  def account?
    user_is_current_user?
  end

  sig { returns(T::Boolean) }
  def connections?
    user_is_current_user?
  end

  private

  sig { returns(T::Boolean) }
  def user_is_current_user?
    current_user && user == current_user
  end
end
