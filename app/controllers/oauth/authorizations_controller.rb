# typed: true
class Oauth::AuthorizationsController < Doorkeeper::AuthorizationsController
  before_action :authenticate_resource_owner!
  after_action :verify_authorized, only: :new

  def new
    skip_authorization
    super
  end

  def create
    super
  end

  def destroy
    super
  end
end
