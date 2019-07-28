# typed: true
class GamePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Game)) }
  attr_reader :game

  sig { params(user: T.nilable(User), game: T.nilable(T.any(ActiveRecord::Relation, Game))).void }
  def initialize(user, game)
    @user = user
    @game = game
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T::Boolean) }
  def show?
    true
  end

  sig { returns(T::Boolean) }
  def create?
    user.present?
  end

  sig { returns(T::Boolean) }
  def update?
    user.present?
  end

  sig { returns(T::Boolean) }
  def destroy?
    user.present?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end

  sig { returns(T::Boolean) }
  def remove_cover?
    user.present?
  end

  sig { returns(T::Boolean) }
  def favorite?
    user.present?
  end

  sig { returns(T::Boolean) }
  def unfavorite?
    user.present?
  end
end
