require 'rails_helper'

RSpec.describe "User Confirmations", type: :request do
  describe "GET new_user_confirmation_path" do
    it 'returns http success' do
      get new_user_confirmation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET user_confirmation_path" do
    let(:user) { create(:user) }

    it "confirms the user's email" do
      get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
      follow_redirect!
      expect(response.body).to include('Your email address has been successfully confirmed.')
    end
  end

  describe 'POST user_confirmation_path' do
    let(:user) { create(:user) }

    it 'sends a confirmation email' do
      post user_confirmation_path, params: { user: { email: user.email } }
      follow_redirect!
      expect(response.body).to include('If your email address exists in our database, you will receive an email with instructions for how to confirm your email address in a few minutes.')
      expect(ActionMailer::Base.deliveries.size).to be(2)
    end
  end
end
