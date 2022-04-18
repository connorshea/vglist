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

  sig { returns(T::Boolean) }
  def index?
    user&.admin? || false
  end

  sig { returns(T::Boolean) }
  def destroy?
    user&.admin? || false
  end
end
