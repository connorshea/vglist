# typed: true
class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  before_action :authenticate_user!
  # Doorkeeper tries to require that the user be an admin in order to create
  # an application, so we skip it to allow 'normal' users to create OAuth
  # apps.
  skip_before_action :authenticate_admin!

  # Only display applications owned by the current user.
  def index
    skip_policy_scope
    @applications = current_user&.oauth_applications
    if @applications.nil?
      skip_authorization
    else
      @applications.each do |app|
        authorize app, policy_class: Oauth::ApplicationPolicy
      end
    end
  end

  def show
    authorize @application, policy_class: Oauth::ApplicationPolicy
    super
  end

  def new
    authorize @application, policy_class: Oauth::ApplicationPolicy
    super
  end

  # Every application must have some owner
  def create
    authorize @application, policy_class: Oauth::ApplicationPolicy
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if T.unsafe(Doorkeeper).configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_url(@application)
    else
      render :new
    end
  end

  def edit
    authorize @application, policy_class: Oauth::ApplicationPolicy
    super
  end

  def update
    authorize @application, policy_class: Oauth::ApplicationPolicy
    super
  end

  def destroy
    authorize @application, policy_class: Oauth::ApplicationPolicy
    super
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
