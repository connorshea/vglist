# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecentLibraryAdditions do
  def add(user, game, at)
    create(:game_purchase, user: user, game: game, created_at: at)
  end

  describe '.games' do
    let(:alice) { create(:confirmed_user) }
    let(:bob) { create(:confirmed_user) }

    it 'lists games newest addition first, each once' do
      older = create(:game)
      newer = create(:game)
      add(alice, older, 3.hours.ago)
      add(bob, newer, 2.hours.ago)
      # Bob adding the older game later moves it to the front, once.
      add(bob, older, 1.hour.ago)

      expect(described_class.games(12)).to eq([older, newer])
    end

    it "leaves out private and banned users' libraries" do
      shown = create(:game)
      add(alice, shown, 3.hours.ago)
      add(create(:private_user), create(:game), 2.hours.ago)
      add(create(:confirmed_user, :banned), create(:game), 1.hour.ago)

      expect(described_class.games(12)).to eq([shown])
    end

    it 'takes at most PER_USER games from each user' do
      bobs = create(:game)
      add(bob, bobs, 1.day.ago)
      alices = create_list(:game, 4)
      alices.each_with_index { |game, i| add(alice, game, (i + 1).minutes.ago) }

      expect(described_class.games(12)).to eq([*alices.first(described_class::PER_USER), bobs])
    end

    it "still shows a game when one user's copy is over their limit" do
      shared = create(:game)
      first, second = create_list(:game, 2)
      add(alice, first, 1.minute.ago)
      add(alice, second, 2.minutes.ago)
      add(alice, shared, 3.minutes.ago)
      add(bob, shared, 1.hour.ago)

      expect(described_class.games(12)).to eq([first, second, shared])
    end

    it 'reads past full batches, resuming between entries added at the same moment' do
      stub_const('RecentLibraryAdditions::BATCH_SIZE', 2)
      at = 1.hour.ago
      games = create_list(:game, 5)
      users = create_list(:confirmed_user, 5)
      games.zip(users).each { |game, user| add(user, game, at) }

      # Same created_at, so the id orders them, newest entry first.
      expect(described_class.games(12)).to eq(games.reverse)
    end

    it 'stops after MAX_SCANNED entries' do
      stub_const('RecentLibraryAdditions::BATCH_SIZE', 2)
      stub_const('RecentLibraryAdditions::MAX_SCANNED', 2)
      games = create_list(:game, 4)
      games.each_with_index { |game, i| add(create(:confirmed_user), game, (i + 1).minutes.ago) }

      expect(described_class.games(12)).to eq(games.first(2))
    end

    it 'returns only as many games as asked for, at most MAX' do
      games = create_list(:game, 3)
      games.each_with_index { |game, i| add(create(:confirmed_user), game, (i + 1).minutes.ago) }

      expect(described_class.games(2)).to eq(games.first(2))
      expect(described_class.games(described_class::MAX + 1).size).to eq(3)
    end

    it 'backfills from the cached IDs when a cached game is deleted' do
      games = create_list(:game, 3)
      games.each_with_index { |game, i| add(create(:confirmed_user), game, (i + 1).minutes.ago) }
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      expect(described_class.games(2)).to eq(games.first(2))
      games.first.destroy!
      expect(described_class.games(2)).to eq(games.last(2))
    end
  end
end
