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
    game_purchase_belongs_to_user?
  end

  def update?
    game_purchase_belongs_to_user?
  end

  def destroy?
    game_purchase_belongs_to_user?
  end

  private

  def game_purchase_belongs_to_user?
    user && game_purchase.user_id == user.id
  end
end
