# typed: strict
class RelationshipPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :follower
  sig { returns(User) }
  attr_reader :followed

  sig { params(follower: T.nilable(User), followed: User).void }
  def initialize(follower, followed)
    @follower = follower
    @followed = followed
  end

  def create?
    follower_is_not_followed? && !follower.nil? && followed.public_account?
  end

  def destroy?
    follower_is_not_followed? && !follower.nil? && followed.public_account?
  end

  protected

  def follower_is_not_followed?
    follower&.id != followed.id
  end
end
