# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameMergeService, type: :service do
  describe "merging two games" do
    let!(:game_a) { create(:game) }
    let!(:game_b) { create(:game) }
    let(:user) { create(:user) }
    let(:game_a_purchase) { create(:game_purchase, game: game_a, user: user) }
    let(:game_a_favorite) { create(:favorite_game, game: game_a, user: user) }
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

    it "moves game_b's purchases into game_a's game_purchases_count" do
      create(:game_purchase, game: game_a)
      create_list(:game_purchase, 2, game: game_b)
      GameMergeService.new(game_a, game_b).merge!
      expect(game_a.reload.game_purchases_count).to eq(3)
    end

    it "recalculates game_a's ratings from both games' purchases", :aggregate_failures do
      create(:game_purchase, game: game_a, rating: 50)
      create(:game_purchase, game: game_b, rating: 80)
      create(:game_purchase, game: game_b, rating: nil)
      GameMergeService.new(game_a, game_b).merge!
      game_a.reload
      expect(game_a.ratings_count).to eq(2)
      expect(game_a.avg_rating).to eq(65)
    end

    it 'does not count a purchase twice when the user owns both games' do
      game_a_purchase
      game_b_purchase
      GameMergeService.new(game_a, game_b).merge!
      expect(game_a.reload.game_purchases_count).to eq(1)
    end

    it 'results in favorites of game_b being updated' do
      user
      game_b_favorite
      GameMergeService.new(game_a, game_b).merge!
      expect(game_b_favorite.reload.game_id).to eq(game_a.id)
    end

    it 'when the user owns both games results in purchase of game_b being deleted' do
      game_a_purchase
      game_b_purchase
      GameMergeService.new(game_a, game_b).merge!
      # For whatever reason, be_destroyed doesn't work here.
      expect(GamePurchase.exists?(game_b_purchase.id)).to eq(false)
    end

    it 'when the user favorites both games results in favorite of game_b being deleted' do
      game_a_favorite
      game_b_favorite
      GameMergeService.new(game_a, game_b).merge!
      # For whatever reason, be_destroyed doesn't work here.
      expect(FavoriteGame.exists?(game_b_favorite.id)).to eq(false)
    end

    it 'returns false when merging a game into itself' do
      expect(GameMergeService.new(game_a, game_a).merge!).to eq(false)
    end

    it 'does not delete the game when merging into itself' do
      expect { GameMergeService.new(game_a, game_a).merge! }.not_to change(Game, :count)
    end
  end
end
