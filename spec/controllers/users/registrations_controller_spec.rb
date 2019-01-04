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

  # rubocop:disable RSpec/Pending
  describe "authenticated user" do
    # TODO: Fix this test.
    pending "This test has a weird issue that causes it to fail. #{__FILE__}"
    # let(:user) { create(:user) }

    # it "can edit password" do
    #   request.env["devise.mapping"] = Devise.mappings[:user]
    #   user.confirm
    #   sign_in user
    #   post :update, params: {
    #     email: user.email,
    #     current_password: user.password,
    #     password: "newpassword",
    #     password_confirmation: "newpassword"
    #   }
    #   expect(response).to have_http_status(:success)
    #   expect(user.reload.password).to eql('newpassword')
    # end
  end
  # rubocop:enable RSpec/Pending

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
