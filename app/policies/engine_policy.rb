class EnginePolicy < ApplicationPolicy
  attr_reader :user, :engine

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
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.present?
  end
end
