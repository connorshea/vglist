# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users::Passwords", type: :request do
  describe "GET /users/password/edit (password reset link from email)" do
    it "redirects to the frontend password reset confirm page with the token" do
      get edit_user_password_path(reset_password_token: "abc123")

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("http://localhost:5173/password/reset/confirm?reset_password_token=abc123")
    end
  end

  describe "POST /users/password (request password reset email)" do
    let(:user) { create(:confirmed_user) }

    it "returns success for a valid email" do
      post user_password_path, params: { user: { email: user.email } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to include("Password reset instructions sent")
    end

    it "returns success even for a nonexistent email to prevent enumeration" do
      post user_password_path, params: { user: { email: "nonexistent@example.com" } }

      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /users/password (reset password with token)" do
    let(:user) { create(:confirmed_user) }

    it "resets the password with a valid token", :aggregate_failures do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to include("Password has been reset successfully")
    end

    it "returns errors for an invalid token" do
      put user_password_path, params: {
        user: {
          reset_password_token: "invalidtoken",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it "returns errors when passwords do not match" do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end
end
