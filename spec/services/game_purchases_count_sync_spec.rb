# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GamePurchasesCountSync, type: :service do
  let!(:owned) { create(:game) }
  let!(:unowned) { create(:game) }

  before(:each) do
    create_list(:game_purchase, 2, game: owned)
    # Simulate drift in both directions, as raw SQL would cause.
    Game.where(id: owned.id).update_all(game_purchases_count: 7) # rubocop:disable Rails/SkipsModelValidations
    Game.where(id: unowned.id).update_all(game_purchases_count: 3) # rubocop:disable Rails/SkipsModelValidations
  end

  it 'recounts every game across batches', :aggregate_failures do
    expect(described_class.call(batch_size: 1)).to eq(2)
    expect(owned.reload.game_purchases_count).to eq(2)
    expect(unowned.reload.game_purchases_count).to eq(0)
  end

  it 'leaves correct counters alone' do
    described_class.call
    expect(described_class.call).to eq(0)
  end
end
