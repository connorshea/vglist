# typed: strict
class GamePolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(T.any(Game::ActiveRecord_Relation, Game))) }
  attr_reader :game

  sig { params(user: T.nilable(User), game: T.nilable(T.any(Game::ActiveRecord_Relation, Game))).void }
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

  sig { returns(T.nilable(T::Boolean)) }
  def add_to_wikidata_blocklist?
    user&.admin?
  end
end
