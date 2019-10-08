# typed: true
class CompanyPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Company)) }
  attr_reader :company

  sig { params(user: T.nilable(User), company: T.nilable(T.any(Company::ActiveRecord_Relation, Company))).void }
  def initialize(user, company)
    @user = user
    @company = company
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

  sig { returns(T::Boolean) }
  def destroy?
    user.present?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end
end
