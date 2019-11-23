# typed: true
class StorePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Store)) }
  attr_reader :store

  sig { params(user: T.nilable(User), store: T.nilable(T.any(Store::ActiveRecord_Relation, Store))).void }
  def initialize(user, store)
    @user = user
    @store = store
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T.nilable(T::Boolean)) }
  def create?
    user.present?
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
