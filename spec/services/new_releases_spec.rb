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
