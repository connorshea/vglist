# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewReleases do
  describe '.games' do
    it 'puts games with covers first, then games with more external IDs, then newer games' do
      bare_newest = create(:game, release_date: Time.zone.today)
      one_id = create(:game, :wikidata_id, release_date: 3.days.ago)
      steam_and_wikidata = create(:game, :wikidata_id, :steam_app_id, release_date: 5.days.ago)
      covered_old = create(:game, :cover, release_date: 10.days.ago)
      covered_with_ids = create(:game, :cover, :pcgamingwiki_id, :giantbomb_id, release_date: 20.days.ago)
      bare_older = create(:game, release_date: 1.day.ago)

      expect(described_class.games(12)).to eq(
        [covered_with_ids, covered_old, steam_and_wikidata, one_id, bare_newest, bare_older]
      )
    end

    it 'blends owners into the score on a log scale, after covers' do
      # 2 IDs = 2 points.
      two_ids = create(:game, :wikidata_id, :steam_app_id, release_date: 1.day.ago)
      # 3 owners = 2 * ln(4) ≈ 2.8 points.
      three_owners = create(:game, release_date: 2.days.ago)
      create_list(:game_purchase, 3, game: three_owners)
      # 1 owner = 2 * ln(2) ≈ 1.4 points.
      one_owner = create(:game, release_date: 3.days.ago)
      create(:game_purchase, game: one_owner)
      # 1 ID + 1 owner ≈ 2.4 points.
      id_and_owner = create(:game, :wikidata_id, release_date: 4.days.ago)
      create(:game_purchase, game: id_and_owner)
      # A cover still wins over any number of owners.
      covered = create(:game, :cover, release_date: 5.days.ago)
      bare = create(:game, release_date: Time.zone.today)

      expect(described_class.games(12)).to eq([covered, three_owners, id_and_owner, two_ids, one_owner, bare])
    end

    it 'leaves out unreleased games and games with no release date' do
      released = create(:game, release_date: 2.days.ago)
      create(:game, :cover, :wikidata_id, release_date: 1.week.from_now)
      create(:game, :cover, :wikidata_id, release_date: nil)

      expect(described_class.games(12)).to eq([released])
    end

    it 'only considers the most recently released games' do
      stub_const('NewReleases::CANDIDATES', 2)
      newest = create(:game, release_date: 1.day.ago)
      newer = create(:game, release_date: 2.days.ago)
      create(:game, :cover, :wikidata_id, release_date: 1.year.ago)

      expect(described_class.games(12)).to eq([newest, newer])
    end

    it 'returns at most the requested number of games, up to MAX' do
      create_list(:game, described_class::MAX + 2, release_date: 1.day.ago)

      expect(described_class.games(3).size).to eq(3)
      expect(described_class.games(100).size).to eq(described_class::MAX)
    end
  end

  describe 'caching' do
    include ActiveSupport::Testing::TimeHelpers

    around(:each) do |example|
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = original
    end

    it 'fills the gap left by a deleted game from the rest of the cached list' do
      first = create(:game, release_date: 1.day.ago)
      second = create(:game, release_date: 2.days.ago)
      third = create(:game, release_date: 3.days.ago)
      expect(described_class.games(2)).to eq([first, second])

      first.destroy!
      expect(described_class.games(2)).to eq([second, third])
    end

    it 'keeps a full shelf after a game is deleted' do
      games = create_list(:game, described_class::MAX + 1, release_date: 1.day.ago)
      expect(described_class.games(described_class::MAX).size).to eq(described_class::MAX)

      games.first.destroy!
      expect(described_class.games(described_class::MAX).size).to eq(described_class::MAX)
    end

    it 'keeps the ranked list until it expires, while still dropping deleted games' do
      first = create(:game, :wikidata_id, release_date: 1.day.ago)
      second = create(:game, release_date: 2.days.ago)
      expect(described_class.games(12)).to eq([first, second])

      create(:game, :cover, release_date: Time.zone.today)
      second.destroy!
      expect(described_class.games(12)).to eq([first])

      travel(described_class::EXPIRES_IN + 1.minute) do
        expect(described_class.games(12).size).to eq(2)
      end
    end
  end
end
