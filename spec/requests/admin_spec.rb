# typed: false
require 'rails_helper'

RSpec.describe "Admin", type: :request do
  describe "GET admin_path" do
    let(:user) { create(:confirmed_user) }
    let(:admin) { create(:confirmed_admin) }

    it "redirects if not signed in" do
      get admin_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      get admin_path
      expect(response).to redirect_to(root_path)
    end

    it "returns http success if signed in as admin" do
      sign_in(admin)
      get admin_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET admin_wikidata_blocklist_path" do
    let(:user) { create(:confirmed_user) }
    let(:admin) { create(:confirmed_admin) }

    it "redirects if not signed in" do
      get admin_wikidata_blocklist_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      get admin_wikidata_blocklist_path
      expect(response).to redirect_to(root_path)
    end

    it "returns http success if signed in as admin" do
      sign_in(admin)
      get admin_wikidata_blocklist_path
      expect(response).to have_http_status(:success)
    end
  end
end
