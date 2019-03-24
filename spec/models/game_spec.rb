require 'rails_helper'

RSpec.describe Game, type: :model do
  subject(:game) { FactoryBot.create(:game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality of wikidata_id' do
      expect(game).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end

    it { should validate_uniqueness_of(:pcgamingwiki_id) }
    it { should validate_length_of(:pcgamingwiki_id).is_at_most(300) }

    it 'allows valid PCGamingWiki IDs' do
      expect(game).to allow_values(
        'Battlefront',
        'Battlefront_II',
        'Battlefront_II_(2018)',
        'Star_Wars:_Knights_of_the_Old_Republic_II_-_The_Sith_Lords',
        '.hack//G.U._Last_Recode'
      ).for(:pcgamingwiki_id)
    end

    it 'disallows invalid PCGamingWiki IDs' do
      expect(game).not_to allow_values(
        'Invalid[Name',
        'Invalid]Name',
        'Invalid\Name',
        'Invalid Name',
        'Invalid<Name',
        'Invalid>Name',
        'Invalid#Name'
      ).for(:pcgamingwiki_id)
    end

    it { should validate_uniqueness_of(:steam_app_id) }
    it 'validates numericality of steam_app_id' do
      expect(game).to validate_numericality_of(:steam_app_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end
  end

  describe "Associations" do
    it { should have_many(:game_purchases) }
    it { should have_many(:purchasers).through(:game_purchases).source(:user) }

    it { should have_many(:game_developers) }
    it { should have_many(:developers).through(:game_developers).source(:company) }

    it { should have_many(:game_publishers) }
    it { should have_many(:publishers).through(:game_publishers).source(:company) }

    it { should have_many(:game_platforms) }
    it { should have_many(:platforms).through(:game_platforms).source(:platform) }

    it { should have_many(:game_genres) }
    it { should have_many(:genres).through(:game_genres).source(:genre) }

    it { should have_many(:game_engines) }
    it { should have_many(:engines).through(:game_engines).source(:engine) }

    it { should belong_to(:series).optional }
  end

  describe "Indexes" do
    it { should have_db_index(:steam_app_id).unique }
  end
end
