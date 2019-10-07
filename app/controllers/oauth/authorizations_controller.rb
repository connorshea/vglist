# typed: true
class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  before_action :authenticate_resource_owner!

  def new
    authorize @application, policy_class: Oauth::AuthorizationPolicy
    super
  end

  def create
    authorize @application, policy_class: Oauth::AuthorizationPolicy
    super
  end

  def destroy
    authorize @application, policy_class: Oauth::AuthorizationPolicy
    super
  end
end
