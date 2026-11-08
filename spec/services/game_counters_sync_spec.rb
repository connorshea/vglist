# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameCountersSync, type: :service do
  let!(:owned) { create(:game) }
  let!(:unowned) { create(:game) }

  before(:each) do
    create(:game_purchase, game: owned, rating: 50)
    create(:game_purchase, game: owned, rating: 75)
    create(:game_purchase, game: owned, rating: nil)
    # Simulate drift in both directions, as raw SQL would cause.
    # rubocop:disable Rails/SkipsModelValidations
    Game.where(id: owned.id).update_all(game_purchases_count: 7, ratings_count: 1, avg_rating: 10)
    Game.where(id: unowned.id).update_all(game_purchases_count: 3, ratings_count: 2, avg_rating: 90)
    # rubocop:enable Rails/SkipsModelValidations
  end

  it 'recalculates every game across batches', :aggregate_failures do
    expect(described_class.call(batch_size: 1)).to eq(2)
    expect(owned.reload).to have_attributes(game_purchases_count: 3, ratings_count: 2, avg_rating: 62.5)
    expect(unowned.reload).to have_attributes(game_purchases_count: 0, ratings_count: 0, avg_rating: nil)
  end

  it 'fixes a game where only the average rating has drifted' do
    described_class.call
    Game.where(id: owned.id).update_all(avg_rating: 10) # rubocop:disable Rails/SkipsModelValidations
    expect { described_class.call }.to change { owned.reload.avg_rating }.from(10).to(62.5)
  end

  it "agrees with Game#update_ratings on rounding" do
    game = create(:game)
    [50, 75, 66].each { |rating| create(:game_purchase, game: game, rating: rating) }
    expect(game.reload.avg_rating).to eq(63.7)
    expect { described_class.call }.not_to(change { game.reload.avg_rating })
  end

  it 'leaves correct counters alone' do
    described_class.call
    expect(described_class.call).to eq(0)
  end
end
