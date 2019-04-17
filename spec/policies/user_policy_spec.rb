require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:user_policy) { described_class.new(current_user, user) }

  describe 'A logged-in user' do
    let(:current_user) { create(:user) }
    let(:user) { create(:user) }

    it { should permit_actions([:index, :show]) }
    it "does not permit actions" do
      expect(user_policy).not_to permit_actions(
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

    it { should permit_actions([:index, :show]) }
    it "does not permit actions" do
      expect(user_policy).not_to permit_actions(
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

    it { should permit_actions([:index, :show, :remove_avatar]) }
    it "does not permit actions" do
      expect(user_policy).not_to permit_actions(
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

    it { should permit_actions([:index, :show, :update_role, :remove_avatar]) }
    it "does not permit actions" do
      expect(user_policy).not_to permit_actions(
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
          :reset_game_library
        ]
      )
    end
    it { should_not permit_actions([:update_role]) }
  end
end
