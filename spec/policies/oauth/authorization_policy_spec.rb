# typed: false
require 'rails_helper'

RSpec.describe Oauth::AuthorizationPolicy, type: :policy do
  subject(:oauth_authorization_policy) { described_class.new(user, application) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:application) { create(:application) }

    it "can do everything" do
      expect(oauth_authorization_policy).to permit_actions([
        :new,
        :create,
        :destroy
      ])
    end
  end

  describe 'An anonymous user' do
    let(:user) { nil }
    let(:application) { create(:application) }

    it "can't do anything" do
      expect(oauth_authorization_policy).to permit_actions([
        :new,
        :create,
        :destroy
      ])
    end
  end
end
