# typed: true
class Oauth::ApplicationPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :application

  def initialize(user, application)
    @user = user
    @application = application
  end

  def index?
    user_is_logged_in
  end

  def show?
    user_owns_application
  end

  def new?
    user_is_logged_in
  end

  def create?
    user_is_logged_in
  end

  def edit?
    user_owns_application
  end

  def update?
    user_owns_application
  end

  def destroy?
    user_owns_application
  end

  private

  def user_is_logged_in
    !user.nil?
  end

  def user_owns_application
    application&.owner&.id == user&.id
  end
end
