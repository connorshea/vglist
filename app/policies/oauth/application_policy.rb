# typed: true
class Oauth::ApplicationPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Doorkeeper::Application)) }
  attr_reader :application

  sig { params(user: T.nilable(User), application: T.nilable(Doorkeeper::Application)).void }
  def initialize(user, application)
    @user = user
    @application = application
  end

  sig { returns(T::Boolean) }
  def index?
    user_is_logged_in
  end

  sig { returns(T::Boolean) }
  def show?
    user_owns_application
  end

  sig { returns(T::Boolean) }
  def new?
    user_is_logged_in
  end

  sig { returns(T::Boolean) }
  def create?
    user_is_logged_in
  end

  sig { returns(T::Boolean) }
  def edit?
    user_owns_application
  end

  sig { returns(T::Boolean) }
  def update?
    user_owns_application
  end

  sig { returns(T::Boolean) }
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
