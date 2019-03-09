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
          :destroy
        ]
      )
    end
  end

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:game_purchase) { create(:game_purchase, user: another_user) }

    it "isn't allowed to modify another user's game purchases" do
      expect(game_purchase_policy).to permit_actions([:index, :show])
      expect(game_purchase_policy).to forbid_actions([:create, :update, :destroy])
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
          :destroy
        ]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:game_purchase) { create(:game_purchase, user: user) }

    it "is allowed to admin do everything" do
      expect(game_purchase_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :update,
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
      expect(game_purchase_policy).not_to permit_actions(
        [
          :create,
          :update,
          :destroy
        ]
      )
    end
  end
end
