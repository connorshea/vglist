# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceGameCountsSync, type: :service do
  let(:genre) { create(:genre) }
  let(:platform) { create(:platform) }
  let(:engine) { create(:engine) }
  let(:series) { create(:series) }
  let(:empty_genre) { create(:genre) }

  before(:each) do
    create_list(:game, 2, genres: [genre], platforms: [platform], engines: [engine], series: series)
    empty_genre
  end

  # Simulate drift in both directions, as raw SQL or old code mid-deploy would cause.
  def drift!
    # rubocop:disable Rails/SkipsModelValidations
    [Genre, Platform, Engine, Series].each { |model| model.update_all(games_count: 9) }
    # rubocop:enable Rails/SkipsModelValidations
  end

  it 'recalculates every table', :aggregate_failures do
    drift!
    expect(described_class.call).to eq(5)
    expect([genre, platform, engine, series].map { |record| record.reload.games_count }).to eq([2, 2, 2, 2])
    expect(empty_genre.reload.games_count).to eq(0)
  end

  it 'leaves correct counts alone' do
    expect(described_class.call).to eq(0)
  end
end
