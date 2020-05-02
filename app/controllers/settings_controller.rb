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

    regex = %r{https://steamcommunity\.com/id/(.*)/}
    @steam_username = @steam_account[:steam_profile_url].match(regex)[1]
  end

  # Export settings
  def export
    @user = current_user
    authorize @user, policy_class: SettingsPolicy
  end

  # Send a JSON file so the user can download their library as JSON.
  def export_as_json
    @user = T.must(current_user)
    authorize @user, policy_class: SettingsPolicy

    @games = GamePurchase.where(user_id: @user.id).includes(:game, :platforms, :stores)

    respond_to do |format|
      format.json do
        export_data = {
          user: {
            id: @user.id,
            username: @user.username
          },
          games: @games.as_json(include: [:game, :platforms, :stores])
        }
        send_data JSON.pretty_generate(export_data), disposition: :json, filename: 'vglist.json'
      end
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
