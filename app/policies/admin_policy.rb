# typed: true
class AdminPolicy < ApplicationPolicy
  sig { returns(User) }
  attr_reader :user
  sig { returns(NilClass) }
  attr_reader :nilable

  sig { params(user: User, nilable: NilClass).void }
  def initialize(user, nilable)
    @user = user
  end

  sig { returns(T::Boolean) }
  def dashboard?
    user.admin?
  end
end
