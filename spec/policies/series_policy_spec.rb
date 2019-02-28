require 'rails_helper'

RSpec.describe SeriesPolicy, type: :policy do
  subject(:series_policy) { described_class.new(user, series) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:series) { create(:series) }

    it "let's a user do everything" do
      expect(series_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A moderator' do
    let(:user) { create(:moderator) }
    let(:series) { create(:series) }

    it "let's a moderator do everything" do
      expect(series_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin' do
    let(:user) { create(:admin) }
    let(:series) { create(:series) }

    it "let's an admin do everything" do
      expect(series_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:series) { create(:series) }

    it { should permit_actions([:index, :show]) }
    it { should_not permit_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
