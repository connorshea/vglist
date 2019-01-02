require 'rails_helper'

RSpec.describe PlatformPolicy do
  subject { described_class.new(user, platform) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:platform) { create(:platform) }

    it { should permit_actions([:index, :show]) }
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:platform) { create(:platform) }

    it { should permit_actions([:index, :show]) }
  end
end
