# typed: true
class Oauth::AuthorizationPolicy < ApplicationPolicy
  sig { returns(T.nilable(User)) }
  attr_reader :user
  sig { returns(T.nilable(Doorkeeper::Application)) }
  attr_reader :application

  sig { params(user: T.nilable(User), application: T.nilable(Doorkeeper::Application)).void }
  def initialize(user, application)
    @user = user
    @application = application
  end

  def new?
    user_is_logged_in
  end

  def create?
    user_is_logged_in
  end

  def destroy?
    user_is_logged_in
  end

  private

  def user_is_logged_in
    !user.nil?
  end
end
