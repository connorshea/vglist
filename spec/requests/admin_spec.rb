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

  describe "DELETE admin_remove_from_wikidata_blocklist_path" do
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:admin) { create(:confirmed_admin) }
    let(:wikidata_blocklist) { create(:wikidata_blocklist) }

    it "redirects if not signed in" do
      delete admin_remove_from_wikidata_blocklist_path(wikidata_blocklist.wikidata_id)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      delete admin_remove_from_wikidata_blocklist_path(wikidata_blocklist.wikidata_id)
      expect(response).to redirect_to(root_path)
    end

    it "redirects if signed in as moderator" do
      sign_in(moderator)
      delete admin_remove_from_wikidata_blocklist_path(wikidata_blocklist.wikidata_id)
      expect(response).to redirect_to(root_path)
    end

    it "deletes a wikidata blocklist item if signed in as admin" do
      sign_in(admin)
      wikidata_blocklist
      expect do
        delete admin_remove_from_wikidata_blocklist_path(wikidata_blocklist.wikidata_id)
      end.to change(WikidataBlocklist, :count).by(-1)
    end
  end

  describe "GET admin_games_without_wikidata_ids" do
    let(:user) { create(:confirmed_user) }
    let(:admin) { create(:confirmed_admin) }

    it "redirects if not signed in" do
      get admin_games_without_wikidata_ids_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      get admin_games_without_wikidata_ids_path
      expect(response).to redirect_to(root_path)
    end

    it "returns http success if signed in as admin" do
      sign_in(admin)
      get admin_games_without_wikidata_ids_path
      expect(response).to have_http_status(:success)
    end
  end
end
