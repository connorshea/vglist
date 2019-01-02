require 'rails_helper'

RSpec.describe ReleasePolicy do
  subject { described_class.new(user, release) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:release) { create(:release) }

    it { is_expected.to permit_actions([:index, :show]) }
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:release) { create(:release) }

    it { is_expected.to permit_actions([:index, :show]) }
  end
end
