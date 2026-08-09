# frozen_string_literal: true

class GamePurchasePolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :game_purchase

  def initialize(user, game_purchase)
    @user = user
    @game_purchase = game_purchase
  end

  def index?
    authorized = user_profile_is_visible?
    return false if authorized.nil?

    return authorized
  end

  def show?
    user_profile_is_visible?
  end

  def create?
    user_signed_in?
  end

  def update?
    game_purchase_belongs_to_user?
  end

  def bulk_update?
    game_purchase_belongs_to_user?
  end

  def destroy?
    game_purchase_belongs_to_user?
  end

  private

  def game_purchase_belongs_to_user?
    user && game_purchase&.user_id == user&.id
  end

  # Game purchases are only visible to other users if their owner has a public
  # account and hasn't been banned, matching UserPolicy#user_profile_is_visible?.
  def user_profile_is_visible?
    owner = game_purchase&.user
    (owner&.public_account? && !owner&.banned?) || game_purchase_belongs_to_user? || user&.admin?
  end

  def user_signed_in?
    user.present?
  end
end
