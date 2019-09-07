# typed: false
require 'rails_helper'

RSpec.describe ActivityPolicy, type: :policy do
  subject(:activity_policy) { described_class.new(user, event) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }

    it "can view both activity feeds" do
      expect(activity_policy).to permit_actions([:global, :following])
    end
  end

  describe 'An anonymous user' do
    let(:user) { nil }
    let(:event) { create(:event) }

    it "can view only global activity" do
      expect(activity_policy).to permit_actions([:global])
      expect(activity_policy).to forbid_actions([:following])
    end
  end
end
