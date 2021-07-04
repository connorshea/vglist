# typed: false
require 'rails_helper'

RSpec.describe StorePolicy, type: :policy do
  subject(:store_policy) { described_class.new(user, store) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:store) { create(:store) }

    it "let's a normal user list, show, and search stores" do
      expect(store_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy stores" do
      expect(store_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:store) { create(:store) }

    it "let's a moderator do everything" do
      expect(store_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:store) { create(:store) }

    it "let's an admin do everything" do
      expect(store_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:store) { create(:store) }

    it { should permit_actions([:index, :show]) }
    it { should forbid_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
