# typed: strict
class EnginePolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Engine)) }
  attr_reader :engine

  sig { params(user: T.nilable(User), engine: T.nilable(Engine)).void }
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
