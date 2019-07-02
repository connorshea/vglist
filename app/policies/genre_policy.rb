# typed: true
class GenrePolicy < ApplicationPolicy
  extend T::Sig
  
  attr_reader :user, :genre

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

  sig { returns(T::Boolean) }
  def create?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def update?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def destroy?
    user_is_moderator_or_admin?
  end

  sig { returns(T::Boolean) }
  def search?
    user.present?
  end

  private

  sig { returns(T::Boolean) }
  def user_is_moderator_or_admin?
    user && (user.moderator? || user.admin?)
  end
end
