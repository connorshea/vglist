# typed: strict
class GenrePolicy < ApplicationPolicy
  extend T::Sig

  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(T.any(Genre::ActiveRecord_Relation, Genre))) }
  attr_reader :genre

  sig { params(user: T.nilable(User), genre: T.nilable(T.any(Genre::ActiveRecord_Relation, Genre))).void }
  def initialize(user, genre)
    @user = user
    @genre = genre
  end

  sig { returns(T::Boolean) }
  def index?
    true
  end

  sig { returns(T::Boolean) }
  def show?
    true
  end

  sig { returns(T.nilable(T::Boolean)) }
  def create?
    user_is_moderator_or_admin?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def update?
    user_is_moderator_or_admin?
  end

  sig { returns(T.nilable(T::Boolean)) }
  def destroy?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end

  private

  sig { returns(T.nilable(T::Boolean)) }
  def user_is_moderator_or_admin?
    user && (user&.moderator? || user&.admin?)
  end
end
