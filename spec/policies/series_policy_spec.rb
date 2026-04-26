# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeriesPolicy, type: :policy do
  subject(:series_policy) { described_class.new(user, series) }

  describe 'A logged-in user' do
    let(:user) { build_stubbed(:user) }
    let(:series) { build_stubbed(:series) }

    it "let's a normal user list, show, and search series'" do
      expect(series_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy series'" do
      expect(series_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator' do
    let(:user) { build_stubbed(:moderator) }
    let(:series) { build_stubbed(:series) }

    it "let's a moderator do everything" do
      expect(series_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin' do
    let(:user) { build_stubbed(:admin) }
    let(:series) { build_stubbed(:series) }

    it "let's an admin do everything" do
      expect(series_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:series) { build_stubbed(:series) }

    it { should permit_actions([:index, :show]) }
    it { should forbid_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
