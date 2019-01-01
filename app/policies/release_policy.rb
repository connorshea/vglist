class ReleasePolicy < ApplicationPolicy
  attr_reader :user, :release

  def initialize(user, release)
    @user = user
    @release = release
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
