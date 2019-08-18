# typed: true
class GamePurchaseEventPolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(GamePurchaseEvent)) }
  attr_reader :game_purchase_event

  sig { params(user: T.nilable(User), game_purchase_event: T.nilable(GamePurchaseEvent)).void }
  def initialize(user, game_purchase_event)
    @user = user
    @game_purchase_event = game_purchase_event
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    user && game_purchase_event&.user_id == user&.id
  end
end
