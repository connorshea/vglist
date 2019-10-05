# typed: true
class Oauth::AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  before_action :authenticate_resource_owner!
  after_action :verify_authorized, only: :index

  def index
    skip_authorization
    skip_policy_scope
    super
  end

  def destroy
    super
  end
end
