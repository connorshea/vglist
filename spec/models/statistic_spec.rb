require 'rails_helper'

RSpec.describe Statistic, type: :model do
  subject(:statistic) { build(:statistic) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(statistic).to be_valid
    end

    it { should validate_numericality_of(:users) }
    it { should validate_numericality_of(:games) }
    it { should validate_numericality_of(:platforms) }
    it { should validate_numericality_of(:series) }
    it { should validate_numericality_of(:engines) }
    it { should validate_numericality_of(:companies) }
    it { should validate_numericality_of(:genres) }
    it { should validate_numericality_of(:stores) }
    it { should validate_numericality_of(:events) }
    it { should validate_numericality_of(:game_purchases) }
    it { should validate_numericality_of(:relationships) }
    it { should validate_numericality_of(:games_with_covers) }
    it { should validate_numericality_of(:games_with_release_dates) }
    it { should validate_numericality_of(:banned_users) }
    it { should validate_numericality_of(:mobygames_ids) }
    it { should validate_numericality_of(:pcgamingwiki_ids) }
    it { should validate_numericality_of(:wikidata_ids) }
    it { should validate_numericality_of(:giantbomb_ids) }
    it { should validate_numericality_of(:steam_app_ids) }
    it { should validate_numericality_of(:epic_games_store_ids) }
    it { should validate_numericality_of(:gog_ids) }
  end
end
