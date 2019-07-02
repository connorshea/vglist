# typed: true
class SeriesPolicy < ApplicationPolicy
  extend T::Sig
  
  sig { returns(User) }
  attr_reader :user
  sig { returns(Series) }
  attr_reader :series

  def initialize(user, series)
    @user = user
    @series = series
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
