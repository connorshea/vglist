require 'rails_helper'

RSpec.describe GamePolicy do
  subject { described_class.new(user, game) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }

    it do
      is_expected.to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:game) { create(:game) }

    it { is_expected.to permit_actions([:index, :show]) }
    it { is_expected.not_to permit_actions([:create, :new, :edit, :update, :destroy]) }
  end
end
