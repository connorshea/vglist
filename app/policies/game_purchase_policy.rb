# typed: true
class GamePurchasePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(GamePurchase)) }
  attr_reader :game_purchase

  sig { params(user: T.nilable(User), game_purchase: T.nilable(GamePurchase)).void }
  def initialize(user, game_purchase)
    @user = user
    @game_purchase = game_purchase
  end

  sig { returns(T::Boolean) }
  def index?
    authorized = user_profile_is_visible?
    return false if authorized.nil?

    return authorized
  end

  sig { returns(T.nilable(T::Boolean)) }
  def show?
    user_profile_is_visible?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def create?
    game_purchase_belongs_to_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def update?
    game_purchase_belongs_to_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def bulk_update?
    game_purchase_belongs_to_user?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    game_purchase_belongs_to_user?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def game_purchase_belongs_to_user?
    user && game_purchase&.user_id == user&.id
  end

  sig { returns(T.nilable(T::Boolean)) }
  def user_profile_is_visible?
    game_purchase&.user&.public_account? || game_purchase_belongs_to_user? || user&.admin?
  end
end
