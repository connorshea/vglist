# typed: false
require 'rails_helper'

RSpec.describe "Settings", type: :request do
  describe "GET settings_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get settings_path
      expect(response).to have_http_status(:success)
    end

    it "redirects for users who aren't logged in" do
      get settings_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET settings_account_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get settings_account_path
      expect(response).to have_http_status(:success)
    end

    it "redirects for users who aren't logged in" do
      get settings_account_path
      expect(response).to redirect_to(root_path)
    end

    it ".well-known/change-password redirects to settings_account_path" do
      sign_in(user)
      get '/.well-known/change-password'
      expect(response).to redirect_to(settings_account_path)
    end
  end

  describe "GET settings_connections_path" do
    let(:user) { create(:confirmed_user) }
    let(:user_with_external_account) { create(:user, :confirmed, :external_account) }

    it "returns http success" do
      sign_in(user)
      get settings_connections_path
      expect(response).to have_http_status(:success)
    end

    it "redirects for users who aren't logged in" do
      get settings_connections_path
      expect(response).to redirect_to(root_path)
    end

    it "returns http success for a user with an external account" do
      sign_in(user_with_external_account)
      get settings_connections_path
      expect(response).to have_http_status(:success)
    end
  end
end
