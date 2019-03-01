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

  def update?
    current_user && user == current_user
  end

  def destroy?
    current_user && user == current_user
  end
end
