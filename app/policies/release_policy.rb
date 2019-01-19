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
end
