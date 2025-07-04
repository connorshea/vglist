require 'rails_helper'

RSpec.describe GamePolicy, type: :policy do
  subject(:game_policy) { described_class.new(user, game) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }

    it 'can do basic things' do
      expect(game_policy).to permit_actions(
        [
          :index,
          :show,
          :search,
          :favorite,
          :unfavorite,
          :favorited
        ]
      )
    end

    it 'cannot create, update, or delete games, remove covers, or merge games' do
      expect(game_policy).to forbid_actions(
        [
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :remove_cover,
          :merge
        ]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:game) { create(:game) }

    it "can do almost everything" do
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
          :remove_cover,
          :favorite,
          :unfavorite,
          :favorited
        ]
      )
    end

    it 'cannot merge games' do
      expect(game_policy).to forbid_actions([:merge])
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:game) { create(:game) }

    it "can do everything" do
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
          :remove_cover,
          :favorite,
          :unfavorite,
          :favorited,
          :merge
        ]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:game) { create(:game) }

    it { should permit_actions([:index, :show]) }

    it "can't do most things" do
      expect(game_policy).to forbid_actions(
        [
          :create,
          :new,
          :edit,
          :update,
          :destroy,
          :search,
          :remove_cover,
          :favorite,
          :unfavorite,
          :favorited,
          :merge
        ]
      )
    end
  end
end
