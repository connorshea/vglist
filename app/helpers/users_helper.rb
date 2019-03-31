module UsersHelper
  def link_steam_account_from_omniauth(user, omniauth_response)
    ExternalAccount.create!(
      user_id: user.id,
      account_type: omniauth_response.provider.to_sym,
      steam_id: omniauth_response.uid,
      steam_profile_url: omniauth_response[:extra][:raw_info][:profileurl]
    )
  end
end
