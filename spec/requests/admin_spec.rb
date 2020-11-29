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
    let(:wikidata_blocklist_entries) { create_list(:wikidata_blocklist, 5) }
    let(:wikidata_blocklist_entry_with_no_user) { create(:wikidata_blocklist, user: nil) }

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

    it "returns http success if signed in as admin with multiple blocklist entries" do
      sign_in(admin)
      wikidata_blocklist_entries
      get admin_wikidata_blocklist_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success if signed in as admin with a blocklist entry with no user" do
      sign_in(admin)
      wikidata_blocklist_entry_with_no_user
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

  describe "GET admin_steam_blocklist_path" do
    let(:user) { create(:confirmed_user) }
    let(:admin) { create(:confirmed_admin) }
    let(:steam_blocklist_entries) { create_list(:steam_blocklist, 5) }
    let(:steam_blocklist_entry_with_no_user) { create(:steam_blocklist, user: nil) }

    it "redirects if not signed in" do
      get admin_steam_blocklist_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      get admin_steam_blocklist_path
      expect(response).to redirect_to(root_path)
    end

    it "returns http success if signed in as admin" do
      sign_in(admin)
      get admin_steam_blocklist_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success if signed in as admin with multiple blocklist entries" do
      sign_in(admin)
      steam_blocklist_entries
      get admin_steam_blocklist_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success if signed in as admin with a blocklist entry with no user" do
      sign_in(admin)
      steam_blocklist_entry_with_no_user
      get admin_steam_blocklist_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new_steam_blocklist_path" do
    let(:admin) { create(:confirmed_admin) }

    it "returns http success" do
      sign_in(admin)
      get admin_new_steam_blocklist_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST add_to_steam_blocklist" do
    let(:admin) { create(:confirmed_admin) }
    let(:game) { create(:game) }
    let(:steam_app_id) { create(:steam_app_id, app_id: 123, game: game) }

    it "creates a new blocklist entry" do
      sign_in(admin)
      expect do
        post admin_add_to_steam_blocklist_path(steam_blocklist: { name: 'Half-Life', steam_app_id: 123 })
      end.to change(SteamBlocklist, :count).by(1)
    end

    it "destroys the SteamAppId" do
      sign_in(admin)
      steam_app_id
      expect do
        post admin_add_to_steam_blocklist_path(steam_blocklist: { name: 'Half-Life', steam_app_id: 123 })
      end.to change(SteamAppId, :count).by(-1)
    end

    it "removes the SteamAppId for a game" do
      sign_in(admin)
      steam_app_id
      post admin_add_to_steam_blocklist_path(steam_blocklist: { name: 'Half-Life', steam_app_id: 123 })
      expect(response).to redirect_to(admin_steam_blocklist_path)
      expect(game.reload.steam_app_ids).to be_empty
    end
  end

  describe "DELETE admin_remove_from_steam_blocklist_path" do
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:admin) { create(:confirmed_admin) }
    let(:steam_blocklist) { create(:steam_blocklist) }

    it "redirects if not signed in" do
      delete admin_remove_from_steam_blocklist_path(steam_blocklist.steam_app_id)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects if signed in as user" do
      sign_in(user)
      delete admin_remove_from_steam_blocklist_path(steam_blocklist.steam_app_id)
      expect(response).to redirect_to(root_path)
    end

    it "redirects if signed in as moderator" do
      sign_in(moderator)
      delete admin_remove_from_steam_blocklist_path(steam_blocklist.steam_app_id)
      expect(response).to redirect_to(root_path)
    end

    it "deletes a steam blocklist item if signed in as admin" do
      sign_in(admin)
      steam_blocklist
      expect do
        delete admin_remove_from_steam_blocklist_path(steam_blocklist.steam_app_id)
      end.to change(SteamBlocklist, :count).by(-1)
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
