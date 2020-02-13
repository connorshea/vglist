# typed: false
require 'rails_helper'

RSpec.describe GamePurchasePolicy, type: :policy do
  subject(:game_purchase_policy) { described_class.new(user, game_purchase) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game_purchase) { create(:game_purchase, user: user) }

    it "is allowed to do everything for their own game purchases" do
      expect(game_purchase_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'A second logged-in user' do
    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:game_purchase) { create(:game_purchase, user: another_user) }

    it "isn't allowed to modify another user's game purchases" do
      # It can create because create only allows you to create for the currently-logged-in user.
      # We don't currently check the value of current_user because of limitations
      # in GraphQL and Pundit.
      expect(game_purchase_policy).to permit_actions([:index, :show, :create])
      expect(game_purchase_policy).to forbid_actions([:update, :destroy, :bulk_update])
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:game_purchase) { create(:game_purchase, user: user) }

    it "is allowed to do everything for their own games" do
      expect(game_purchase_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:owning_user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: owning_user) }

    it "is allowed to see the game purchases but not modify them" do
      expect(game_purchase_policy).to permit_actions(
        [
          :index,
          :show,
          # It can create because create only allows you to create for the logged-in user.
          # We don't currently check the value of current_user because of limitations
          # in GraphQL and Pundit.
          :create
        ]
      )
      expect(game_purchase_policy).to forbid_actions(
        [
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'An admin user when the user that is being viewed is private' do
    let(:private_user) { create(:private_user) }
    let(:user) { create(:confirmed_admin) }
    let(:game_purchase) { create(:game_purchase, user: private_user) }

    it "is allowed to see the game purchases but not modify them" do
      expect(game_purchase_policy).to permit_actions(
        [
          :index,
          :show,
          # It can create because create only allows you to create for the logged-in user.
          # We don't currently check the value of current_user because of limitations
          # in GraphQL and Pundit.
          :create
        ]
      )
      expect(game_purchase_policy).to forbid_actions(
        [
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'A normal user when the user that is being viewed is private' do
    let(:private_user) { create(:private_user) }
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: private_user) }

    it "is allowed to see and do nothing" do
      # It can create because create only allows you to create for the logged-in user.
      # We don't currently check the value of current_user because of limitations
      # in GraphQL and Pundit.
      expect(game_purchase_policy).to permit_action(:create)
      expect(game_purchase_policy).to forbid_actions(
        [
          :index,
          :show,
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'A user that is not logged in when the user that is being viewed is private' do
    let(:private_user) { create(:private_user) }
    let(:user) { nil }
    let(:game_purchase) { create(:game_purchase, user: private_user) }

    it "is allowed to see and do nothing" do
      expect(game_purchase_policy).to forbid_actions(
        [
          :index,
          :show,
          :create,
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:game_purchase) { create(:game_purchase) }

    it { should permit_actions([:index, :show]) }

    it "isn't allowed to do most things" do
      expect(game_purchase_policy).to forbid_actions(
        [
          :create,
          :update,
          :bulk_update,
          :destroy
        ]
      )
    end
  end
end
