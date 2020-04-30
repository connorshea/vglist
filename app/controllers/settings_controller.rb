# typed: true
class SettingsController < ApplicationController
  before_action :authenticate_user!

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

  # Import settings
  def import
    @user = current_user
    authorize @user, policy_class: SettingsPolicy

    @steam_account = ExternalAccount.find_by(user_id: current_user&.id, account_type: :steam)
    return if @steam_account.nil?

    @unmatched_games = cookies[:unmatched_games].nil? || cookies[:unmatched_games].blank? ? nil : JSON.parse(cookies[:unmatched_games])

    regex = %r{https://steamcommunity\.com/id/(.*)/}
    @steam_username = @steam_account[:steam_profile_url].match(regex)[1]
    # nilify the cookie to make sure it doesn't display more than once.
    cookies[:unmatched_games] = nil
  end

  # Export settings
  def export
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  # Send a JSON file so the user can download their library as JSON.
  def export_as_json
    @user = current_user
    authorize @user, policy_class: SettingsPolicy

    @games = GamePurchase.where(user_id: @user&.id).includes(:game)

    respond_to do |format|
      format.json { send_data JSON.pretty_generate(@games.as_json(include: :game)), disposition: :json, filename: 'vglist.json' }
    end
  end

  # TODO: Make this require logging in again?
  def api_token
    @user = current_user

    authorize @user, policy_class: SettingsPolicy

    respond_to do |format|
      format.json { render json: @user&.authentication_token.to_json }
    end
  end
end
