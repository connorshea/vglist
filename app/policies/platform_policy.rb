# typed: true
class PlatformPolicy < ApplicationPolicy
  attr_reader :user, :platform

  def initialize(user, platform)
    @user = user
    @platform = platform
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user_is_moderator_or_admin?
  end

  def update?
    user_is_moderator_or_admin?
  end

  def destroy?
    user_is_moderator_or_admin?
  end

  def search?
    user.present?
  end

  private

  def user_is_moderator_or_admin?
    user && (user.moderator? || user.admin?)
  end
end
