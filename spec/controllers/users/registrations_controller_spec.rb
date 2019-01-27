require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  describe "authenticated user" do
    let(:user) { create(:user) }

    it "can access edit page" do
      request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user
      get :edit
      expect(response).to have_http_status(:found)
    end
  end

  describe "new user" do
    it "can be created" do
      request.env["devise.mapping"] = Devise.mappings[:user]
      post :create, params: {
        email: "johndoe@example.com",
        username: "johndoe",
        password: "password",
        password_confirmation: "password"
      }
      expect(response).to have_http_status(:success)
    end
  end
end
