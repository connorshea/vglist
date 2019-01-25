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
    user && (user.moderator? || user.admin?)
  end

  def update?
    user && (user.moderator? || user.admin?)
  end

  def destroy?
    user && (user.moderator? || user.admin?)
  end

  def search?
    user.present?
  end
end
