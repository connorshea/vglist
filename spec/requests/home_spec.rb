# typed: false
require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET root_path" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET root_path as normal user" do
    let(:user) { create(:confirmed_user) }

    it "returns http success" do
      sign_in(user)
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET root_path as an admin" do
    let(:admin) { create(:confirmed_admin) }

    it "returns http success" do
      sign_in(admin)
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
