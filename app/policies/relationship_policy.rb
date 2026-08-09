# frozen_string_literal: true

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

  # Unlike following, unfollowing doesn't require a public account: a user who
  # follows a public account that later becomes private still needs to be able
  # to remove themselves from its follower list.
  def destroy?
    follower_is_not_followed? && !follower.nil?
  end

  protected

  def follower_is_not_followed?
    follower&.id != followed.id
  end
end
