class SeriesPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :series

  def initialize(user, series)
    @user = user
    @series = series
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
    user&.moderator? || user&.admin?
  end
end
