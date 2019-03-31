require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe 'link Steam account from Omniauth data' do
    let(:user) { create(:confirmed_user) }
    let(:user_with_external_account) { create(:user_with_external_account) }

    it 'creates an external account' do
      # Create an omniauth object with only the absolutely necessary attributes.
      omniauth_response = {
        uid: '123456789',
        provider: 'steam',
        extra: {
          raw_info: {
            profileurl: 'https://steamcommunity.com/id/username/'
          }
        }
      }

      expect do
        helper.link_steam_account_from_omniauth(user, omniauth_response)
      end.to change(ExternalAccount, :count).by(1)
    end

    it 'does not create a second external account' do
      # Create an omniauth object with only the absolutely necessary attributes.
      omniauth_response = {
        uid: '123456789',
        provider: 'steam',
        extra: {
          raw_info: {
            profileurl: 'https://steamcommunity.com/id/username/'
          }
        }
      }

      # Need to have rspec create the user before we try to change it,
      # otherwise the external account won't exist before the expect block.
      user_with_external_account

      expect do
        helper.link_steam_account_from_omniauth(user_with_external_account, omniauth_response)
      end.to change(ExternalAccount, :count).by(0)
    end
  end
end
