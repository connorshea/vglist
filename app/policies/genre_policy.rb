class GenrePolicy < ApplicationPolicy
  attr_reader :user, :genre

  def initialize(user, genre)
    @user = user
    @genre = genre
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user && (user.moderator? || user.admin?)
  end

  def update?
    user && (user.moderator? || user.admin?)
  end

  def destroy?
    user && (user.moderator? || user.admin?)
  end

  def search?
    user.present?
  end
end
