# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlatformPolicy, type: :policy do
  subject(:platform_policy) { described_class.new(user, platform) }

  describe 'A logged-in user' do
    let(:user) { build_stubbed(:user) }
    let(:platform) { build_stubbed(:platform) }

    it "let's a normal user list, show, and search platforms" do
      expect(platform_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy platforms" do
      expect(platform_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { build_stubbed(:moderator) }
    let(:platform) { build_stubbed(:platform) }

    it "let's a moderator do everything" do
      expect(platform_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { build_stubbed(:admin) }
    let(:platform) { build_stubbed(:platform) }

    it "let's an admin do everything" do
      expect(platform_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:platform) { build_stubbed(:platform) }

    it { should permit_actions([:index, :show]) }
    it { should forbid_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
