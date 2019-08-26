# typed: false
require 'rails_helper'

RSpec.describe ActivityPolicy, type: :policy do
  subject(:activity_policy) { described_class.new(user, game_purchase_event) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game_purchase_event) { create(:game_purchase_event) }

    it "can view the activity index" do
      expect(activity_policy).to permit_actions([:index])
    end
  end
end
