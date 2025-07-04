class EnginePolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :engine

  def initialize(user, engine)
    @user = user
    @engine = engine
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
    user && (user&.moderator? || user&.admin?)
  end
end
