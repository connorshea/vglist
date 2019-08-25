# typed: false
require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:user_policy) { described_class.new(current_user, user) }

  describe 'A logged-in user' do
    let(:current_user) { create(:user) }
    let(:user) { create(:user) }

    it { should permit_actions([:index, :show, :statistics, :compare]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:current_user) { nil }
    let(:user) { create(:user) }

    it { should permit_actions([:index, :show, :statistics, :compare]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library
        ]
      )
    end
  end

  describe 'A user that is an moderator' do
    let(:current_user) { create(:moderator) }
    let(:user) { create(:user) }

    it { should permit_actions([:index, :show, :remove_avatar, :statistics, :compare]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update_role,
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library
        ]
      )
    end
  end

  describe 'A user that is an admin' do
    let(:current_user) { create(:admin) }
    let(:user) { create(:user) }

    it { should permit_actions([:index, :show, :update_role, :remove_avatar, :statistics, :compare]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library
        ]
      )
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
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :statistics,
          :compare
        ]
      )
    end
    it { should_not permit_actions([:update_role]) }
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
          :remove_avatar,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library,
          :statistics,
          :compare
        ]
      )
    end

    it { should_not permit_actions([:update_role]) }
  end

  describe "An admin that is looking at a private user's profile" do
    let(:current_user) { create(:admin) }
    let(:user) { create(:private_user) }

    it { should permit_actions([:index, :show, :update_role, :remove_avatar, :statistics, :compare]) }
    it "does not permit actions" do
      expect(user_policy).to forbid_actions(
        [
          :update,
          :steam_import,
          :connect_steam,
          :disconnect_steam,
          :reset_game_library
        ]
      )
    end
  end

  describe "A normal user looking at a private user's profile" do
    let(:current_user) { create(:user) }
    let(:user) { create(:private_user) }

    it { should permit_actions([:index]) }
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
          :reset_game_library
        ]
      )
    end
  end

  describe "A user that is not logged in looking at a private user's profile" do
    let(:current_user) { nil }
    let(:user) { create(:private_user) }

    it { should permit_actions([:index]) }
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
          :reset_game_library
        ]
      )
    end
  end
end
