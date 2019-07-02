# typed: true
class EnginePolicy < ApplicationPolicy
  extend T::Sig
  
  attr_reader :user, :engine

  def initialize(user, engine)
    @user = user
    @engine = engine
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T::Boolean) }
  def show?
    true
  end

  sig { returns(T::Boolean) }
  def create?
    user.present?
  end

  sig { returns(T::Boolean) }
  def update?
    user.present?
  end

  sig { returns(T::Boolean) }
  def destroy?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end

  private

  sig { returns(T::Boolean) }
  def user_is_moderator_or_admin?
    user && (user.moderator? || user.admin?)
  end
end
