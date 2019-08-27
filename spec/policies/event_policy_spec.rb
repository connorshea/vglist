# typed: false
require 'rails_helper'

RSpec.describe EventPolicy, type: :policy do
  subject(:event_policy) { described_class.new(user, event) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:event) { create(:event, user: user) }

    it "is allowed to delete their own events" do
      expect(event_policy).to permit_actions([:destroy])
    end
  end

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:another_user) { create(:user) }
    let(:event) { create(:event, user: another_user) }

    it "isn't allowed to modify another user's events" do
      expect(event_policy).to forbid_actions([:destroy])
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:event) { create(:event) }

    it "is not allowed to delete an event" do
      expect(event_policy).to forbid_actions([:destroy])
    end
  end
end
