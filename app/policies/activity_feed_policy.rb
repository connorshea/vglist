# typed: true
class ActivityFeedPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(GamePurchaseEvent)) }
  attr_reader :event

  sig { params(user: T.nilable(User), event: T.nilable(T.any(ActiveRecord::Relation, GamePurchaseEvent))).void }
  def initialize(user, event)
    @user = user
    @event = event
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    game_purchase_belongs_to_user?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def game_purchase_belongs_to_user?
    user && @event.game_purchase&.user_id == user&.id
  end
end
