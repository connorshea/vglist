require 'rails_helper'

RSpec.describe GamesHelper, type: :helper do
  describe 'game in user library' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:user_with_game) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user_with_game, game: game) }

    it 'returns true when game is in user library' do
      allow(controller).to receive(:current_user).and_return(user_with_game)
      game_purchase
      expect(helper.game_in_user_library?(game)).to be(true)
    end

    it 'returns false when game is not in user library' do
      allow(controller).to receive(:current_user).and_return(user)
      game_purchase
      expect(helper.game_in_user_library?(game)).to be(false)
    end
  end

  describe 'game in user favorites' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:user_with_favorite) { create(:confirmed_user) }
    let(:favorite_game) { create(:favorite_game, user: user_with_favorite, game: game) }

    it 'returns true when game is in user favorites' do
      allow(controller).to receive(:current_user).and_return(user_with_favorite)
      favorite_game
      expect(helper.game_in_user_favorites?(game)).to be(true)
    end

    it 'returns false when game is not in user favorites' do
      allow(controller).to receive(:current_user).and_return(user)
      favorite_game
      expect(helper.game_in_user_favorites?(game)).to be(false)
    end
  end
end
