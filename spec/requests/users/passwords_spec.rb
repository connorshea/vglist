require 'rails_helper'

RSpec.describe "User Password", type: :request do
  describe "GET new_user_password_path" do
    it 'returns http success' do
      get new_user_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_user_password_path" do
    let(:user) { create(:confirmed_user) }

    it 'returns http success' do
      password_token = user.send_reset_password_instructions
      get edit_user_password_path, params: { reset_password_token: password_token }
      expect(response).to have_http_status(:success)
    end

    it 'fails without a valid token' do
      get edit_user_password_path
      follow_redirect!
      expect(response.body).to include("You can&#39;t access this page without coming from a password reset email. If you do come from a password reset email, please make sure you used the full URL provided.")
    end
  end

  describe "POST user_password_path" do
    let(:user) { create(:confirmed_user) }

    it 'returns a successful response' do
      post user_password_path, params: { user: { email: user.email } }
      follow_redirect!
      expect(response.body).to include('If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.')
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
