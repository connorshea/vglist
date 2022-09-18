# typed: strict
class PlatformPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.untyped) }
  attr_reader :platform

  sig { params(user: T.nilable(User), platform: T.untyped).void }
  def initialize(user, platform)
    @user = user
    @platform = platform
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T::Boolean) }
  def show?
    true
  end

  sig { returns(T.nilable(T::Boolean)) }
  def create?
    user_is_moderator_or_admin?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def update?
    user_is_moderator_or_admin?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def user_is_moderator_or_admin?
    user && (user&.moderator? || user&.admin?)
  end
end
