require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  describe "authenticated user" do
    let(:user) { create(:user) }

    it "can sign out" do
      request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
      post :destroy, params: {}
      expect(response).to have_http_status(:found)
    end
  end

  describe "user login page" do
    let(:user) { User.new(email: "johndoe1@example.com", password: "password") }

    it "allows users to access the login page" do
      request.env["devise.mapping"] = Devise.mappings[:user]
      get :new
      expect(response).to have_http_status(:success)
    end

    it "allows users to login" do
      request.env["devise.mapping"] = Devise.mappings[:user]
      get :new
      post :create, params: { email: "johndoe1@example.com", password: "password" }
      expect(response).to have_http_status(:success)
    end
  end
end
