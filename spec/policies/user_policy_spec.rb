require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class.new(current_user, user) }

  describe 'A logged-in user' do
    let(:current_user) { create(:user) }
    let(:user) { create(:user) }

    it { is_expected.to permit_actions([:index, :show]) }
  end

  describe 'A user that is not logged in' do
    let(:current_user) { nil }
    let(:user) { create(:user) }

    it { is_expected.to permit_actions([:index, :show]) }
  end
end
