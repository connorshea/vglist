# typed: false
require 'rails_helper'

RSpec.describe AdminPolicy, type: :policy do
  subject(:admin_policy) { described_class.new(user, record) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:record) { nil }

    it 'defaults to disallowing everything' do
      expect(admin_policy).to forbid_actions(
        [
          :dashboard,
          :wikidata_blocklist,
          :remove_from_wikidata_blocklist,
          :games_without_wikidata_ids
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:record) { nil }

    it 'defaults to disallowing everything' do
      expect(admin_policy).to forbid_actions(
        [
          :dashboard,
          :wikidata_blocklist,
          :remove_from_wikidata_blocklist,
          :games_without_wikidata_ids
        ]
      )
    end
  end

  describe 'A user that is a moderator' do
    let(:user) { create(:moderator) }
    let(:record) { nil }

    it 'defaults to disallowing everything' do
      expect(admin_policy).to forbid_actions(
        [
          :dashboard,
          :wikidata_blocklist,
          :remove_from_wikidata_blocklist,
          :games_without_wikidata_ids
        ]
      )
    end
  end

  describe 'A user that is an admin' do
    let(:user) { create(:admin) }
    let(:record) { nil }

    it 'allows everything' do
      expect(admin_policy).to permit_actions(
        [
          :dashboard,
          :wikidata_blocklist,
          :remove_from_wikidata_blocklist,
          :games_without_wikidata_ids
        ]
      )
    end
  end
end
