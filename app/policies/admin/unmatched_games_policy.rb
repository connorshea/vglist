# typed: true
class Admin::UnmatchedGamesPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(NilClass) }
  attr_reader :nilable

  sig { params(user: T.nilable(User), _nilable: NilClass).void }
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
