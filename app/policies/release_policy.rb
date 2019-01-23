class ReleasePolicy < ApplicationPolicy
  attr_reader :user, :release

  def initialize(user, release)
    @user = user
    @release = release
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.present?
  end
end
