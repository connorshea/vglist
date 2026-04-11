require 'rails_helper'

RSpec.describe "Api::Auth", type: :request do
  describe "POST /api/auth/sign_in" do
    let(:user) { create(:confirmed_user) }

    it "returns a JWT token for valid credentials", :aggregate_failures do
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['token']).to be_present
      expect(json['user']['id']).to eq(user.id)
      expect(json['user']['username']).to eq(user.username)
      expect(json['user']['email']).to eq(user.email)
    end

    it "returns an error for invalid credentials" do
      post api_auth_sign_in_path, params: { email: user.email, password: "wrong" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq("Invalid email or password.")
    end

    it "returns an error for a nonexistent email" do
      post api_auth_sign_in_path, params: { email: "nonexistent@example.com", password: "password" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq("Invalid email or password.")
    end

    it "returns an error for a banned user" do
      banned_user = create(:banned_user)
      post api_auth_sign_in_path, params: { email: banned_user.email, password: "password" }

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to eq("Your account has been banned.")
    end

    it "returns an error for an unconfirmed user" do
      unconfirmed_user = create(:user)
      post api_auth_sign_in_path, params: { email: unconfirmed_user.email, password: "password" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq("You must confirm your email address before signing in.")
    end

    it "returns a token that can decode to the user id" do
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }

      json = JSON.parse(response.body)
      decoded = JwtService.decode(json['token'])
      expect(decoded.first['user_id']).to eq(user.id)
    end

    it "returns a token that includes the user's jwt_version" do
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }

      json = JSON.parse(response.body)
      decoded = JwtService.decode(json['token'])
      expect(decoded.first['jwt_version']).to eq(user.jwt_version)
    end

    it "returns a token that passes decode_and_verify" do
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }

      json = JSON.parse(response.body)
      expect(JwtService.decode_and_verify(json['token'])).to eq(user)
    end
  end

  describe "POST /api/auth/sign_up" do
    it "creates a new user account" do
      post api_auth_sign_up_path, params: {
        username: "newuser",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['message']).to include("Account created successfully")
      expect(User.find_by(email: "newuser@example.com")).to be_present
    end

    it "returns errors for invalid params" do
      post api_auth_sign_up_path, params: {
        username: "",
        email: "invalid",
        password: "short",
        password_confirmation: "mismatch"
      }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it "returns errors for a duplicate email" do
      existing_user = create(:confirmed_user)
      post api_auth_sign_up_path, params: {
        username: "newuser",
        email: existing_user.email,
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe "GET /api/auth/me" do
    let(:user) { create(:confirmed_user) }

    it "returns the current user when authenticated with a JWT", :aggregate_failures do
      token = JwtService.encode(user)
      get api_auth_me_path, headers: { 'Authorization': "Bearer #{token}" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user']['id']).to eq(user.id)
      expect(json['user']['username']).to eq(user.username)
      expect(json['user']['email']).to eq(user.email)
      expect(json['user']['role']).to eq(user.role)
      expect(json['user']['slug']).to eq(user.slug)
    end

    it "returns unauthorized when no token is provided" do
      get api_auth_me_path

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq("Not authenticated.")
    end

    it "returns unauthorized for an invalid JWT" do
      get api_auth_me_path, headers: { 'Authorization': "Bearer invalid.token.here" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for an expired JWT" do
      payload = { user_id: user.id, exp: 1.day.ago.to_i, iat: 2.days.ago.to_i }
      expired_token = JWT.encode(payload, Rails.application.secret_key_base, 'HS256')

      get api_auth_me_path, headers: { 'Authorization': "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for a revoked JWT" do
      token = JwtService.encode(user)
      JwtService.revoke_all!(user)

      get api_auth_me_path, headers: { 'Authorization': "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/auth/sign_out" do
    let(:user) { create(:confirmed_user) }

    it "revokes the token and returns success", :aggregate_failures do
      token = JwtService.encode(user)
      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq("Signed out successfully.")
    end

    it "invalidates the token for subsequent requests" do
      token = JwtService.encode(user)
      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }

      get api_auth_me_path, headers: { 'Authorization': "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized when no token is provided" do
      delete api_auth_sign_out_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for an already-revoked token" do
      token = JwtService.encode(user)
      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }
      expect(response).to have_http_status(:success)

      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not invalidate other users' tokens" do
      other_user = create(:confirmed_user)
      token = JwtService.encode(user)
      other_token = JwtService.encode(other_user)

      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }

      get api_auth_me_path, headers: { 'Authorization': "Bearer #{other_token}" }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user']['id']).to eq(other_user.id)
    end

    it "allows signing in again after sign out", :aggregate_failures do
      token = JwtService.encode(user)
      delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }

      # Old token no longer works
      get api_auth_me_path, headers: { 'Authorization': "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)

      # Sign in again to get a new token
      post api_auth_sign_in_path, params: { email: user.email, password: "password" }
      new_token = JSON.parse(response.body)['token']

      # New token works
      get api_auth_me_path, headers: { 'Authorization': "Bearer #{new_token}" }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user']['id']).to eq(user.id)
    end

    it "increments the user's jwt_version" do
      token = JwtService.encode(user)
      expect {
        delete api_auth_sign_out_path, headers: { 'Authorization': "Bearer #{token}" }
      }.to change { user.reload.jwt_version }.by(1)
    end
  end
end
