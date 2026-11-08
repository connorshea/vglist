# frozen_string_literal: true

require 'rails_helper'

# Genres, platforms, engines and series keep a `games_count` counter cache,
# which their "Most games" sort and game counts read.
# Covers four models with the same behaviour, so it isn't about one class.
RSpec.describe 'games_count counter caches' do # rubocop:disable RSpec/DescribeClass
  {
    genre: :genre_ids,
    platform: :platform_ids,
    engine: :engine_ids
  }.each do |resource, ids_attribute|
    describe resource.to_s.capitalize do
      let(:record) { create(resource) }
      let(:game) { create(:game) }

      it 'counts games added to it' do
        expect { game.update!(ids_attribute => [record.id]) }.to change { record.reload.games_count }.from(0).to(1)
      end

      # Assigning IDs deletes the join rows without callbacks.
      it 'stops counting a game when it is removed from the game' do
        game.update!(ids_attribute => [record.id])
        expect { game.update!(ids_attribute => []) }.to change { record.reload.games_count }.from(1).to(0)
      end

      it 'stops counting a game that is deleted' do
        game.update!(ids_attribute => [record.id])
        expect { game.destroy! }.to change { record.reload.games_count }.from(1).to(0)
      end
    end
  end

  describe 'Series' do
    let(:series) { create(:series) }
    let(:other_series) { create(:series) }

    it 'counts games in the series' do
      expect { create(:game, series: series) }.to change { series.reload.games_count }.from(0).to(1)
    end

    it 'moves a game between series' do
      game = create(:game, series: series)
      game.update!(series: other_series)
      expect([series.reload.games_count, other_series.reload.games_count]).to eq([0, 1])
    end

    it 'stops counting a game that is deleted' do
      game = create(:game, series: series)
      expect { game.destroy! }.to change { series.reload.games_count }.from(1).to(0)
    end
  end

  it 'sorts by the stored count' do
    big = create(:genre)
    small = create(:genre)
    create_list(:game, 2, genres: [big])
    create(:game, genres: [small])

    expect(Genre.where(id: [big.id, small.id]).most_games.to_a).to eq([big, small])
  end
end
