# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EnginePolicy, type: :policy do
  subject(:engine_policy) { described_class.new(user, engine) }

  describe 'A logged-in user' do
    let(:user) { build_stubbed(:user) }
    let(:engine) { build_stubbed(:engine) }

    it "let's a normal user list, show, and search engines" do
      expect(engine_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy engines" do
      expect(engine_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:engine) { build_stubbed(:engine) }

    it 'permits index and show' do
      expect(engine_policy).to permit_actions(
        [:index, :show]
      )
    end

    it "doesn't allow anything else" do
      expect(engine_policy).to forbid_actions(
        [:create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { build_stubbed(:moderator) }
    let(:engine) { build_stubbed(:engine) }

    it "let's a moderator do everything" do
      expect(engine_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { build_stubbed(:admin) }
    let(:engine) { build_stubbed(:engine) }

    it "let's an admin do everything" do
      expect(engine_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end
end
