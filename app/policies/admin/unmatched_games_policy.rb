# typed: true
class Admin::UnmatchedGamesPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :nilable

  def initialize(user, _nilable)
    @user = user
  end

  def index?
    user&.admin? || false
  end

  def destroy?
    user&.admin? || false
  end
end
