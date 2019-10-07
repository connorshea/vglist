# typed: true
class Oauth::AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  before_action :authenticate_resource_owner!

  def index
    skip_authorization
    skip_policy_scope
    super
  end

  def destroy
    skip_authorization
    super
  end
end
