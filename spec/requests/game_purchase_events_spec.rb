# typed: false
require 'rails_helper'

RSpec.describe "GamePurchaseEvents", type: :request do
  describe "DELETE game_purchase_event_path" do
    let(:user) { create(:confirmed_user) }
    let!(:event) { create(:game_purchase_event, user: user) }

    it "deletes a game purchase event" do
      sign_in(user)
      expect do
        delete game_purchase_event_path(id: event.id)
      end.to change(GamePurchaseEvent, :count).by(-1)
    end
  end
end
