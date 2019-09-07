# typed: false
require 'rails_helper'

RSpec.describe "Activity", type: :request do
  describe "GET activity_path" do
    it "returns http success" do
      get activity_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET activity_following_path" do
    let(:user) { create(:confirmed_user) }

    it "returns http success if signed in" do
      sign_in(user)
      get activity_following_path
      expect(response).to have_http_status(:success)
    end

    it "returns http redirect if not signed in" do
      get activity_following_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
