require 'rails_helper'

RSpec.describe PlatformPolicy do
  subject(:platform_policy) { described_class.new(user, platform) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:platform) { create(:platform) }

    it "let's a normal user list and show platforms" do
      expect(platform_policy).to permit_actions(
        [:index, :show]
      )
    end

    it "doesn't let a normal user create, update, or destroy platforms" do
      expect(platform_policy).not_to permit_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:platform) { create(:platform) }

    it "let's a moderator do everything" do
      expect(platform_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:platform) { create(:platform) }

    it "let's an admin do everything" do
      expect(platform_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:platform) { create(:platform) }

    it { should permit_actions([:index, :show]) }
    it { should_not permit_actions([:create, :new, :edit, :update, :destroy]) }
  end
end
