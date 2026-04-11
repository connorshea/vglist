# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def destroy?
    user && (event&.user_id == user&.id || user&.moderator? || user&.admin?)
  end
end
