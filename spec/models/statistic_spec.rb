# typed: false
require 'rails_helper'

RSpec.describe Statistic, type: :model do
  subject(:statistic) { build(:statistic) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(statistic).to be_valid
    end

    [
      :users,
      :games,
      :platforms,
      :series,
      :engines,
      :companies,
      :genres,
      :stores,
      :events,
      :game_purchases,
      :relationships,
      :games_with_covers,
      :games_with_release_dates,
      :banned_users,
      :mobygames_ids,
      :pcgamingwiki_ids,
      :wikidata_ids,
      :giantbomb_ids,
      :steam_app_ids,
      :epic_games_store_ids,
      :gog_ids,
      :igdb_ids,
      :company_versions,
      :game_versions,
      :genre_versions,
      :engine_versions,
      :platform_versions,
      :series_versions
    ].each do |statistic|
      it { should validate_numericality_of(statistic) }
    end
  end
end
