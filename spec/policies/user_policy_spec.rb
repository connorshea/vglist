# typed: false
require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:user_policy) { described_class.new(current_user, user) }

  describe 'A logged-in user' do
    let(:current_user) { create(:user) }
    let(:user) { create(:user) }

    it "permits actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :ban,
          :unban
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:current_user) { nil }
    let(:user) { create(:user) }

    it "permits actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :ban,
          :unban
        ]
      )
    end
  end

  describe 'A user that is a moderator' do
    let(:current_user) { create(:moderator) }
    let(:user) { create(:user) }

    it "permits actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :remove_avatar,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites,
          :ban,
          :unban
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token
        ]
      )
    end
  end

  describe 'A user that is an admin' do
    let(:current_user) { create(:admin) }
    let(:user) { create(:user) }

    it 'permits actions' do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :update_role,
          :remove_avatar,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites,
          :ban,
          :unban
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token
        ]
      )
    end
  end

  describe "A moderator looking at an admin's profile" do
    let(:current_user) { create(:moderator) }
    let(:user) { create(:admin) }

    # It allows unbanning because banning a user revokes their role, so it
    # shouldn't really ever occur that a user is both an admin _and_ banned.
    it "does not permit banning" do
      expect(user_policy).to forbid_actions([:ban])
    end
  end

  describe "An admin looking at a moderator's profile" do
    let(:current_user) { create(:admin) }
    let(:user) { create(:moderator) }

    it "permits banning and unbanning" do
      expect(user_policy).to permit_actions([:ban, :unban])
    end
  end

  describe 'A user editing/looking at their own profile' do
    let(:current_user) { create(:user) }
    let(:user) { current_user }

    it "permits most actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :update,
          :search,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :ban,
          :unban
        ]
      )
    end
  end

  describe 'A private user looking at their own profile' do
    let(:current_user) { create(:private_user) }
    let(:user) { current_user }

    it "permits most actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :update,
          :search,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :ban,
          :unban
        ]
      )
    end
  end

  describe "An admin that is looking at a private user's profile" do
    let(:current_user) { create(:admin) }
    let(:user) { create(:private_user) }

    it "permits actions" do
      expect(user_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :update_role,
          :remove_avatar,
          :statistics,
          :compare,
          :activity,
          :following,
          :followers,
          :favorites,
          :ban,
          :unban
        ]
      )
    end

    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token
        ]
      )
    end
  end

  describe "A normal user looking at a private user's profile" do
    let(:current_user) { create(:user) }
    let(:user) { create(:private_user) }

    it { should permit_actions([:index, :search]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :show,
          :update,
          :update_role,
          :remove_avatar,
          :statistics,
          :compare,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :activity,
          :following,
          :followers,
          :favorites,
          :ban,
          :unban
        ]
      )
    end
  end

  describe "A user that is not logged in looking at a private user's profile" do
    let(:current_user) { nil }
    let(:user) { create(:private_user) }

    it { should permit_actions([:index, :search]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :show,
          :update_role,
          :remove_avatar,
          :statistics,
          :compare,
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :reset_token,
          :activity,
          :following,
          :followers,
          :favorites,
          :ban,
          :unban
        ]
      )
    end
  end
end
