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
  end
end
