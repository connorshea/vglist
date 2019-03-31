class SettingsController < ApplicationController
  # Profile things
  def profile
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  # Account settings
  def account
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  def steam_api_test
    puts JSON.parse(open("https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{current_user.uid}&include_appinfo=1&include_played_free_games=1").read)

    skip_authorization
    respond_to do |format|
      format.json { 'test' }
    end
  end
end
