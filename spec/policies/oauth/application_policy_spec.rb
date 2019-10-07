# typed: false
require 'rails_helper'

RSpec.describe Oauth::ApplicationPolicy, type: :policy do
  subject(:oauth_application_policy) { described_class.new(user, application) }

  describe 'A logged-in user that owns an application' do
    let(:user) { create(:user) }
    let(:application) { create(:application, owner: user) }

    it "can do everything with an application they own" do
      expect(oauth_application_policy).to permit_actions(
        [
          :index,
          :show,
          :new,
          :create,
          :edit,
          :update,
          :destroy
        ]
      )
    end
  end

  describe 'A logged-in user that does not own an application' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:application) { create(:application, owner: user2) }

    it "can only view their own application or create new applications" do
      expect(oauth_application_policy).to permit_actions(
        [
          :index,
          :new,
          :create
        ]
      )

      expect(oauth_application_policy).to forbid_actions(
        [
          :show,
          :edit,
          :update,
          :destroy
        ]
      )
    end
  end

  describe 'An anonymous user' do
    let(:user) { nil }
    let(:application) { create(:application) }

    it "can't do anything" do
      expect(oauth_application_policy).to forbid_actions(
        [
          :index,
          :show,
          :new,
          :create,
          :edit,
          :update,
          :destroy
        ]
      )
    end
  end
end
