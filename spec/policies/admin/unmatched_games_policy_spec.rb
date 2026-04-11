# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::UnmatchedGamesPolicy, type: :policy do
  subject(:policy) { described_class.new(user, nil) }

  describe 'a user that is not logged in' do
    let(:user) { nil }

    it 'forbids index and destroy' do
      expect(policy).to forbid_actions([:index, :destroy])
    end
  end

  describe 'a logged-in non-admin user' do
    let(:user) { create(:user) }

    it 'forbids index and destroy' do
      expect(policy).to forbid_actions([:index, :destroy])
    end
  end

  describe 'a moderator' do
    let(:user) { create(:moderator) }

    it 'forbids index and destroy' do
      expect(policy).to forbid_actions([:index, :destroy])
    end
  end

  describe 'an admin' do
    let(:user) { create(:admin) }

    it 'permits index and destroy' do
      expect(policy).to permit_actions([:index, :destroy])
    end
  end
end
