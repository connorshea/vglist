class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :steam

  def steam
    authorize current_user

    # Custom method to link an existing account with a Steam account
    omniauth_response = request.env["omniauth.auth"]
    helpers.link_steam_account_from_omniauth(current_user, omniauth_response)

    if ExternalAccount.find_by(user_id: current_user.id, account_type: :steam)
      flash[:success] = "Successfully connected Steam account #{omniauth_response[:extra][:raw_info][:personaname]}."
    else
      flash[:error] = "Failed to connect your Steam account."
    end

    redirect_to settings_connections_path
  end

  def failure
    skip_authorization
    redirect_to settings_connections_path
  end
end
