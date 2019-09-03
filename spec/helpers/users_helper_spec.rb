# typed: false
require 'rails_helper'

RSpec.describe GamesHelper, type: :helper do
  describe 'game in user library' do
    let(:user1) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:relationship) { create(:relationship, follower: user1, followed: user2) }

    it 'returns true when current_user is following user' do
      relationship
      allow(controller).to receive(:current_user).and_return(user1)
      expect(helper.current_user_following?(user2)).to be(true)
    end

    it 'returns false when current_user is not following user' do
      relationship
      allow(controller).to receive(:current_user).and_return(user2)
      expect(helper.current_user_following?(user1)).to be(false)
    end
  end
end
