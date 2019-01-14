require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET users_path" do
    it "returns http success" do
      get users_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET release_path" do
    let(:user) { create(:user) }

    it "returns http success" do
      get user_path(id: user.id)
      expect(response).to have_http_status(:success)
    end
  end
end
