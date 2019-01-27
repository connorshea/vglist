require 'rails_helper'

RSpec.describe "User Password", type: :request do
  describe "GET new_user_password_path" do
    it 'returns http success' do
      get new_user_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT user_password_path" do
    let(:user) { create(:confirmed_user) }

    it 'reset user password' do
      password_token = user.send_reset_password_instructions
      put user_password_path, params: {
        user: {
          reset_password_token: password_token,
          password: 'newpassword',
          password_confirmation: 'newpassword'
        }
      }
      follow_redirect!
      expect(response.body).to include('Your password has been changed successfully.')
    end
  end
end
