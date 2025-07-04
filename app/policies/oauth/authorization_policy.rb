# typed: true
class Oauth::AuthorizationPolicy < ApplicationPolicy
  attr_reader :user
  attr_reader :application

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
