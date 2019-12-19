# typed: strict
class SeriesPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(T.any(Series::ActiveRecord_Relation, Series))) }
  attr_reader :series

  sig { params(user: T.nilable(User), series: T.nilable(T.any(Series::ActiveRecord_Relation, Series))).void }
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
    user&.moderator? || user&.admin?
  end
end
