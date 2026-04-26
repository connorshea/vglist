# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RelationshipPolicy, type: :policy do
  subject(:relationship_policy) { described_class.new(current_user, followed) }

  describe 'A logged-in user' do
    let(:current_user) { build_stubbed(:confirmed_user) }
    let(:followed) { build_stubbed(:confirmed_user) }

    it { should permit_actions([:create, :destroy]) }
  end

  describe 'A logged-in user trying to follow themselves' do
    let(:user) { build_stubbed(:user) }
    let(:current_user) { user }
    let(:followed) { user }

    it { should forbid_actions([:create, :destroy]) }
  end

  describe 'An anonymous user' do
    let(:current_user) { nil }
    let(:followed) { build_stubbed(:confirmed_user) }

    it { should forbid_actions([:create, :destroy]) }
  end
end
