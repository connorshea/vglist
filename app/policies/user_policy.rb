class UserPolicy < ApplicationPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
