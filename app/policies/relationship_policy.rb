class RelationshipPolicy < ApplicationPolicy
  attr_reader :follower
  attr_reader :followed

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
