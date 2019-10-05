# typed: false
class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  before_action :authenticate_user!
  after_action :verify_authorized, only: :index

  def index
    skip_authorization
    skip_policy_scope
    @applications = current_user&.oauth_applications
  end

  # Every application must have some owner
  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_url(@application)
    else
      render :new
    end
  end

  private

  def set_application
    @application = current_user&.oauth_applications&.find(params[:id])
  end

  def application_params
    params.typed_require(:doorkeeper_application).permit(
      :name,
      :redirect_uri,
      :scopes,
      :confidential
    )
  end
end
