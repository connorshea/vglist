require 'rails_helper'

RSpec.describe GamePolicy, type: :policy do
  subject(:game_policy) { described_class.new(user, game) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }

    it do
      expect(game_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :search,
          :remove_cover
        ]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:game) { create(:game) }

    it "let's a moderator do everything" do
      expect(game_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :search,
          :remove_cover
        ]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:game) { create(:game) }

    it "let's an admin do everything" do
      expect(game_policy).to permit_actions(
        [
          :index,
          :show,
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :search,
          :remove_cover
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:game) { create(:game) }

    it { should permit_actions([:index, :show]) }

    it "doesn't let an anonymous user do most things" do
      expect(game_policy).not_to permit_actions(
        [
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :search,
          :remove_cover
        ]
      )
    end
  end
end
