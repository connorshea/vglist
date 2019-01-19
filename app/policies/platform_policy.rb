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
end
