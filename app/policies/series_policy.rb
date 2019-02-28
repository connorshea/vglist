class SeriesPolicy < ApplicationPolicy
  attr_reader :user, :series

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
    user.present?
  end

  def update?
    user.present?
  end

  def destroy?
    user.present?
  end

  def search?
    user.present?
  end
end
