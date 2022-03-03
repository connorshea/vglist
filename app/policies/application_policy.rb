# typed: true
# Defines defaults for all policies.
class ApplicationPolicy
  extend T::Sig

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.untyped) }
  attr_reader :record

  sig { params(user: T.nilable(User), record: T.untyped).void }
  def initialize(user, record)
    @user = user
    @record = record
  end

  sig { returns(T::Boolean) }
  def index?
    false
  end

  sig { returns(T.nilable(T::Boolean)) }
  def show?
    false
  end

  sig { returns(T.nilable(T::Boolean)) }
  def create?
    false
  end

  sig { returns(T.nilable(T::Boolean)) }
  def new?
    create?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def update?
    false
  end

  sig { returns(T.nilable(T::Boolean)) }
  def edit?
    update?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    false
  end

  sig { returns(T.nilable(T::Boolean)) }
  def search?
    false
  end
end
