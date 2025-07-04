# typed: strong
class ActivityPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def global?
    true
  end

  def following?
    !user.nil?
  end
end
