# typed: strong
class ActivityPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(T.any(Views::NewEvent, Views::NewEvent::NewEventType))) }
  attr_reader :event

  sig { params(user: T.nilable(User), event: T.nilable(T.any(Views::NewEvent, Views::NewEvent::NewEventType))).void }
  def initialize(user, event)
    @user = user
    @event = event
  end

  sig { returns(T::Boolean) }
  def global?
    true
  end

  sig { returns(T::Boolean) }
  def following?
    !user.nil?
  end
end
