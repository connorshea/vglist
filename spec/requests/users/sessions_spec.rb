# typed: false
require 'rails_helper'

RSpec.describe "User Session", type: :request do
  describe "GET new_user_session_path" do
    it 'returns http success' do
      get new_user_session_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST user_session_path" do
    let(:user) { create(:confirmed_user) }
    let(:user_attributes) { { email: user.email, password: user.password } }
    let(:banned_user) { create(:banned_user) }
    let(:banned_user_attributes) { { email: banned_user.email, password: banned_user.password } }
    let(:unconfirmed_user) { create(:user) }
    let(:unconfirmed_user_attributes) { { email: unconfirmed_user.email, password: unconfirmed_user.password } }

    it 'signs in a user' do
      post user_session_path, params: { user: user_attributes }
      follow_redirect!
      expect(response.body).to include('Signed in successfully.')
    end

    it 'does not sign in a banned user' do
      post user_session_path, params: { user: banned_user_attributes }
      follow_redirect!
      expect(response.body).not_to include('Signed in successfully.')
      expect(response.body).to include('Your account has been banned.')
    end

    it 'does not sign in a user that has not confirmed their account' do
      post user_session_path, params: { user: unconfirmed_user_attributes }
      follow_redirect!
      expect(response.body).not_to include('Signed in successfully.')
      expect(response.body).to include('You have to confirm your email address before continuing.')
    end
  end

  describe "DELETE destroy_user_session_path" do
    let(:user) { create(:confirmed_user) }

    it 'signs the user out' do
      sign_in(user)

      delete destroy_user_session_path
      follow_redirect!
      expect(response.body).to include('Signed out successfully.')
    end
  end
end
