# typed: strict
class EventPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Views::NewEvent::NewEventType)) }
  attr_reader :event

  sig { params(user: T.nilable(User), event: T.nilable(Views::NewEvent::NewEventType)).void }
  def initialize(user, event)
    @user = user
    @event = event
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    user && event&.user_id == user&.id
  end
end
