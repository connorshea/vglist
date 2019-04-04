require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET users_path" do
    it "returns http success" do
      get users_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET user_path" do
    let(:user) { create(:user) }
    let(:user_with_avatar) { create(:user_with_avatar) }
    let(:user_with_game_purchase) { create(:user_with_game_purchase) }

    it "returns http success" do
      get user_path(id: user.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for user with avatar" do
      get user_path(id: user_with_avatar.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for user with game purchase" do
      get user_path(id: user_with_game_purchase.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST update_role_user_path" do
    let(:admin) { create(:confirmed_admin) }
    let(:moderator) { create(:confirmed_moderator) }
    let(:user) { create(:confirmed_user) }
    let(:another_user) { create(:confirmed_user) }

    it "makes the user a moderator" do
      sign_in(admin)
      post update_role_user_path(id: user.id, role: "moderator")
      expect(user.reload.role).to eql('moderator')
    end

    it "makes the user an admin" do
      sign_in(admin)
      post update_role_user_path(id: user.id, role: "admin")
      expect(user.reload.role).to eql('admin')
    end

    it "makes the moderator a member" do
      sign_in(admin)
      post update_role_user_path(id: moderator.id, role: "member")
      expect(moderator.reload.role).to eql('member')
    end

    it "doesn't accept an invalid role" do
      sign_in(admin)
      post update_role_user_path(id: user.id, role: "dipstick")
      follow_redirect!
      expect(response.body).to include('Invalid role.')
    end

    it "moderator cannot make another user a moderator" do
      sign_in(moderator)
      post update_role_user_path(id: user.id, role: "moderator")
      expect(response).to redirect_to(root_path)
      expect(user.reload.role).to eql('member')
      expect(user.reload.role).not_to eql('moderator')
    end

    it "user cannot make another user a moderator" do
      sign_in(another_user)
      post update_role_user_path(id: user.id, role: "moderator")
      expect(response).to redirect_to(root_path)
      expect(user.reload.role).to eql('member')
      expect(user.reload.role).not_to eql('moderator')
    end

    it "user cannot make themselves a moderator" do
      sign_in(user)
      post update_role_user_path(id: user.id, role: "moderator")
      expect(response).to redirect_to(root_path)
      expect(user.reload.role).to eql('member')
      expect(user.reload.role).not_to eql('moderator')
    end

    it "admin cannot make themselves a moderator" do
      sign_in(admin)
      post update_role_user_path(id: admin.id, role: "moderator")
      expect(response).to redirect_to(root_path)
      expect(admin.reload.role).to eql('admin')
      expect(admin.reload.role).not_to eql('moderator')
    end
  end

  describe "DELETE remove_avatar_user_path" do
    let(:user) { create(:confirmed_user_with_avatar) }
    let(:another_user) { create(:confirmed_user) }

    it "removes the avatar from the current user" do
      sign_in(user)
      delete remove_avatar_user_path(user.id),
        params: { id: user.id }
      expect(response).to redirect_to(user_url(user))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Avatar successfully removed.")
    end

    it "doesn't let a user remove the avatar from a different user" do
      sign_in(another_user)
      delete remove_avatar_user_path(user.id),
        params: { id: user.id }
      expect(response).to redirect_to(root_path)
      expect(user.reload.avatar).to be_attached
    end
  end

  describe "DELETE disconnect_steam_user_path" do
    let(:user) { create(:confirmed_user) }
    let(:user_with_external_account) { create(:user, :confirmed, :external_account) }

    it "removes the Steam account from the current user" do
      sign_in(user_with_external_account)
      delete disconnect_steam_user_path(user_with_external_account.id),
        params: { id: user_with_external_account.id }
      expect(response).to redirect_to(settings_connections_path)
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Successfully disconnected Steam account.")
    end

    it "does not remove the Steam account from the current user if they have no Steam account connected" do
      sign_in(user)
      delete disconnect_steam_user_path(user.id),
        params: { id: user.id }
      expect(response).to redirect_to(settings_connections_path)
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Unable to disconnect Steam account.")
    end
  end

  describe "DELETE reset_game_library_user_path" do
    let(:user) { create(:confirmed_user) }
    let(:user_with_game_purchase) { create(:user_with_game_purchase, :confirmed) }

    it "removes game purchases from the current user" do
      sign_in(user_with_game_purchase)
      delete reset_game_library_user_path(user_with_game_purchase.id),
        params: { id: user_with_game_purchase.id }
      expect(response).to redirect_to(user_path(user_with_game_purchase))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Successfully reset game library.")
    end

    it "removes all game purchases from the current user" do
      sign_in(user_with_game_purchase)
      expect do
        delete reset_game_library_user_path(user_with_game_purchase.id),
          params: { id: user_with_game_purchase.id }
      end.to change(GamePurchase, :count).by(-1)

      expect(GamePurchase.find_by(user_id: user_with_game_purchase.id)).to be(nil)
    end

    it "removes game purchases from the current user even if they don't have any game purchases" do
      sign_in(user)
      delete reset_game_library_user_path(user.id),
        params: { id: user.id }
      expect(response).to redirect_to(user_path(user))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Successfully reset game library.")
    end
  end
end
