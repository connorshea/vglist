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

    it 'signs in a user' do
      post user_session_path, params: { user: user_attributes }
      follow_redirect!
      expect(response.body).to include('Signed in successfully.')
    end
  end

  describe "DELETE destroy_user_session_path" do
    let(:user) { create(:confirmed_user) }

    it 'creates a user' do
      sign_in(user)

      delete destroy_user_session_path
      follow_redirect!
      expect(response.body).to include('Signed out successfully.')
    end
  end
end
