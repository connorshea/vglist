require 'rails_helper'

RSpec.describe ReleasePolicy, type: :policy do
  subject(:release_policy) { described_class.new(user, release) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:release) { create(:release) }

    it 'permits everything' do
      expect(release_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:release) { create(:release) }

    it 'permits index and show' do
      expect(release_policy).to permit_actions(
        [:index, :show]
      )
    end

    it "doesn't allow anything else" do
      expect(release_policy).not_to permit_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:release) { create(:release) }

    it "let's a moderator do everything" do
      expect(release_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:release) { create(:release) }

    it "let's an admin do everything" do
      expect(release_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end
end
