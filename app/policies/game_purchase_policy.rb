class GamePurchasePolicy < ApplicationPolicy
  attr_reader :user, :game_purchase

  def initialize(user, game_purchase)
    @user = user
    @game_purchase = game_purchase
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user && game_purchase.user_id == user.id
  end

  def update?
    user && game_purchase.user_id == user.id
  end

  def destroy?
    user && game_purchase.user_id == user.id
  end
end
