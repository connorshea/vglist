# typed: false
require 'rails_helper'

RSpec.describe GameMergeService, type: :service do
  describe "merging two games" do
    let!(:game_a) { create(:game) }
    let!(:game_b) { create(:game) }
    let(:user) { create(:user) }
    let(:game_b_purchase) { create(:game_purchase, game: game_b, user: user) }
    let(:game_b_favorite) { create(:favorite_game, game: game_b, user: user) }

    it 'results in game_b being deleted' do
      GameMergeService.new(game_a, game_b).merge!
      expect(game_a).not_to be_destroyed
      expect(game_b).to be_destroyed
    end

    it 'results in purchases of game_b being updated' do
      user
      game_b_purchase
      GameMergeService.new(game_a, game_b).merge!
      expect(game_b_purchase.reload.game_id).to eq(game_a.id)
    end

    it 'results in favorites of game_b being updated' do
      user
      game_b_favorite
      GameMergeService.new(game_a, game_b).merge!
      expect(game_b_favorite.reload.game_id).to eq(game_a.id)
    end
  end
end
