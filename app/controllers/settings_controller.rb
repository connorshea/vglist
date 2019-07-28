# typed: true
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

  # Connections settings
  def connections
    @user = current_user
    authorize @user, policy_class: SettingsPolicy

    @steam_account = ExternalAccount.find_by(user_id: current_user.id, account_type: :steam)
    return if @steam_account.nil?

    @unmatched_games = params[:unmatched_games]

    regex = %r{https://steamcommunity\.com/id/(.*)/}
    @steam_username = @steam_account[:steam_profile_url].match(regex)[1]
  end
end
