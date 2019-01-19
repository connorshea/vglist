require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject(:application_policy) { described_class.new(user, record) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:record) { nil }

    it 'defaults to disallowing everything' do
      expect(application_policy).not_to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:record) { nil }

    it 'defaults to disallowing everything' do
      expect(application_policy).not_to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end
end
