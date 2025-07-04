# typed: strict
class GamePolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :game

  def initialize(user, game)
    @user = user
    @game = game
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user&.moderator? || user&.admin?
  end

  def update?
    user&.moderator? || user&.admin?
  end

  def destroy?
    user&.moderator? || user&.admin?
  end

  def search?
    user.present?
  end

  def remove_cover?
    user&.moderator? || user&.admin?
  end

  def favorite?
    user.present?
  end

  def unfavorite?
    user.present?
  end

  def favorited?
    user.present?
  end

  def add_to_wikidata_blocklist?
    user&.admin?
  end

  def merge?
    user&.admin?
  end
end
