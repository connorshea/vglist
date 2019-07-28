# typed: false
require 'rails_helper'

RSpec.describe "User Registration", type: :request do
  describe "GET new_user_registration_path" do
    it 'returns http success' do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET edit_user_registration_path" do
    let(:user) { create(:confirmed_user) }

    it 'returns http success' do
      sign_in(user)

      get edit_user_registration_path
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST user_registration_path" do
    let(:user_attributes) { attributes_for(:user) }

    it 'creates a user' do
      expect {
        post user_registration_path, params: { user: user_attributes }
      }.to change(User, :count).by(1)
    end
  end

  describe "DELETE user_registration_path" do
    let(:user) { create(:confirmed_user) }

    it 'creates a user' do
      sign_in(user)

      expect {
        delete user_registration_path
      }.to change(User, :count).by(-1)
    end
  end
end
