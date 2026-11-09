# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpcomingReleases do
  describe '.games' do
    it 'puts games with covers first, then games with more external IDs, then sooner games' do
      bare_soonest = create(:game, release_date: 2.days.from_now)
      one_id = create(:game, :wikidata_id, release_date: 5.days.from_now)
      steam_and_wikidata = create(:game, :wikidata_id, :steam_app_id, release_date: 1.week.from_now)
      covered_later = create(:game, :cover, release_date: 1.month.from_now)
      covered_with_ids = create(:game, :cover, :pcgamingwiki_id, :giantbomb_id, release_date: 2.months.from_now)
      bare_later = create(:game, release_date: 3.days.from_now)

      expect(described_class.games(12)).to eq(
        [covered_with_ids, covered_later, steam_and_wikidata, one_id, bare_soonest, bare_later]
      )
    end

    it 'blends owners into the score, after covers' do
      two_ids = create(:game, :wikidata_id, :steam_app_id, release_date: 2.days.from_now)
      three_owners = create(:game, release_date: 3.days.from_now)
      create_list(:game_purchase, 3, game: three_owners)
      covered = create(:game, :cover, release_date: 4.days.from_now)

      expect(described_class.games(12)).to eq([covered, three_owners, two_ids])
    end

    it 'leaves out released games, games with no release date and games beyond the window' do
      upcoming = create(:game, release_date: 2.days.from_now)
      create(:game, :cover, :wikidata_id, release_date: Time.zone.today)
      create(:game, :cover, :wikidata_id, release_date: 1.week.ago)
      create(:game, :cover, :wikidata_id, release_date: nil)
      create(:game, :cover, :wikidata_id, release_date: (described_class::WINDOW + 1.week).from_now)

      expect(described_class.games(12)).to eq([upcoming])
    end

    it 'never includes a game that the new releases shelf can include' do
      games = (-3..3).map { |days| create(:game, release_date: days.days.from_now) }

      expect(described_class.games(12) + NewReleases.games(12)).to match_array(games)
    end

    it 'only considers the soonest upcoming games' do
      stub_const('UpcomingReleases::CANDIDATES', 2)
      soonest = create(:game, release_date: 2.days.from_now)
      sooner = create(:game, release_date: 3.days.from_now)
      create(:game, :cover, :wikidata_id, release_date: 3.months.from_now)

      expect(described_class.games(12)).to eq([soonest, sooner])
    end

    it 'returns at most the requested number of games, up to MAX' do
      create_list(:game, described_class::MAX + 2, release_date: 1.week.from_now)

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
      first = create(:game, release_date: 2.days.from_now)
      second = create(:game, release_date: 3.days.from_now)
      third = create(:game, release_date: 4.days.from_now)
      expect(described_class.games(2)).to eq([first, second])

      first.destroy!
      expect(described_class.games(2)).to eq([second, third])
    end

    it 'drops a game whose release date arrives while the list is cached' do
      first = create(:game, release_date: 2.days.from_now)
      second = create(:game, release_date: 3.days.from_now)
      expect(described_class.games(12)).to eq([first, second])

      first.update!(release_date: Time.zone.today)
      expect(described_class.games(12)).to eq([second])
    end

    it 'keeps the ranked list until it expires' do
      first = create(:game, :wikidata_id, release_date: 2.days.from_now)
      second = create(:game, release_date: 3.days.from_now)
      expect(described_class.games(12)).to eq([first, second])

      covered = create(:game, :cover, release_date: 1.week.from_now)
      expect(described_class.games(12)).to eq([first, second])

      travel(described_class::EXPIRES_IN + 1.minute) do
        expect(described_class.games(12)).to eq([covered, first, second])
      end
    end
  end
end
