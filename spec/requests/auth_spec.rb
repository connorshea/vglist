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
      expired_token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')

      get api_auth_me_path, headers: { 'Authorization': "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
