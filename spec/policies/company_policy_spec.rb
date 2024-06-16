# typed: false
require 'rails_helper'

RSpec.describe CompanyPolicy, type: :policy do
  subject(:company_policy) { described_class.new(user, company) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:company) { create(:company) }

    it "let's a normal user list, show, and search companies" do
      expect(company_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy companies" do
      expect(company_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator' do
    let(:user) { create(:moderator) }
    let(:company) { create(:company) }

    it "let's a moderator do everything" do
      expect(company_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin' do
    let(:user) { create(:admin) }
    let(:company) { create(:company) }

    it "let's an admin do everything" do
      expect(company_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:company) { create(:company) }

    it { should permit_actions([:index, :show]) }
    it { should forbid_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
