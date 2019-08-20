# typed: false
require 'rails_helper'

RSpec.describe GamePurchaseEventPolicy, type: :policy do
  subject(:game_purchase_event_policy) { described_class.new(user, game_purchase_event) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game_purchase_event) { create(:game_purchase_event, user: user) }

    it "is allowed to delete their own game purchase events" do
      expect(game_purchase_event_policy).to permit_actions([:destroy])
    end
  end

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:game_purchase_event) { create(:game_purchase_event, user: another_user) }

    it "isn't allowed to modify another user's game purchase events" do
      expect(game_purchase_event_policy).to forbid_actions([:destroy])
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:game_purchase_event) { create(:game_purchase_event) }

    it "is not allowed to delete a game purchase event" do
      expect(game_purchase_event_policy).to forbid_actions([:destroy])
    end
  end
end
