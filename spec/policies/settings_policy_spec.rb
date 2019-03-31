require 'rails_helper'

RSpec.describe SettingsPolicy, type: :policy do
  subject(:settings_policy) { described_class.new(current_user, current_user) }

  describe 'A logged-in user' do
    let(:current_user) { create(:user) }

    it { should permit_actions([:profile, :account, :connections]) }
  end

  describe 'An anonymous user' do
    let(:current_user) { nil }

    it { should_not permit_actions([:profile, :account, :connections]) }
  end
end
