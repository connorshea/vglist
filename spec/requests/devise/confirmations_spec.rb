# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users::Confirmations", type: :request do
  describe "GET /users/confirmation (confirm email)" do
    it "confirms the user and redirects to frontend login with confirmed=true" do
      user = create(:user)
      token = user.confirmation_token

      get user_confirmation_path(confirmation_token: token)

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("http://localhost:5173/login?confirmed=true")
    end

    it "redirects to frontend login with confirmation_error=true for an invalid token" do
      get user_confirmation_path(confirmation_token: "invalidtoken")

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("http://localhost:5173/login?confirmation_error=true")
    end
  end

  describe "POST /users/confirmation (resend confirmation instructions)" do
    it "returns success for an unconfirmed user" do
      user = create(:user)

      post user_confirmation_path, params: { user: { email: user.email } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to include("Confirmation instructions sent")
    end
  end
end
