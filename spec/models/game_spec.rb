# typed: false
require 'rails_helper'

RSpec.describe Game, type: :model do
  subject(:game) { build(:game) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }

    it 'validates the avg_rating' do
      expect(game).to validate_numericality_of(:avg_rating)
        .allow_nil
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    end

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality of wikidata_id' do
      expect(game).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end

    it { should validate_uniqueness_of(:pcgamingwiki_id).allow_nil }
    it { should validate_length_of(:pcgamingwiki_id).is_at_most(300) }

    it 'allows valid PCGamingWiki IDs' do
      expect(game).to allow_values(
        'Battlefront',
        'Battlefront_II',
        'Battlefront_II_(2018)',
        'Star_Wars:_Knights_of_the_Old_Republic_II_-_The_Sith_Lords',
        '.hack//G.U._Last_Recode',
        'Z'
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

    it { should validate_uniqueness_of(:mobygames_id).allow_nil }
    it { should validate_length_of(:mobygames_id).is_at_most(300) }

    it 'allows valid MobyGames IDs' do
      expect(game).to allow_values(
        'star-wars-battlefront-ii',
        'star-wars-battlefront-ii_',
        'borderlands-2',
        'star-wars-knights-of-the-old-republic-ii-the-sith-lords',
        'windows/disciples-ii-dark-prophecy',
        'ps3/game-name',
        'z'
      ).for(:mobygames_id)
    end

    it 'disallows invalid MobyGames IDs' do
      expect(game).not_to allow_values(
        'CapitalLetters',
        'Game with spaces in name',
        'PS3/game'
      ).for(:mobygames_id)
    end

    it { should validate_uniqueness_of(:giantbomb_id).allow_nil }
    it { should validate_length_of(:giantbomb_id).is_at_most(100) }

    it 'allows valid Giant Bomb IDs' do
      expect(game).to allow_values(
        '3030-1539',
        '3025-953',
        '3030-7110'
      ).for(:giantbomb_id)
    end

    it 'disallows invalid Giant Bomb IDs' do
      expect(game).not_to allow_values(
        '30301539',
        '1-1234',
        '1234-'
      ).for(:giantbomb_id)
    end

    it { should validate_uniqueness_of(:epic_games_store_id).allow_nil }
    it { should validate_length_of(:epic_games_store_id).is_at_most(300) }

    it 'allows valid Epic Games Store IDs' do
      expect(game).to allow_values(
        'superliminal',
        'darksiders3',
        'hades',
        'little-inferno',
        'z'
      ).for(:epic_games_store_id)
    end

    it 'disallows invalid Epic Games Store IDs' do
      expect(game).not_to allow_values(
        'Game with spaces in name',
        '<script></script>'
      ).for(:epic_games_store_id)
    end

    it { should validate_length_of(:gog_id).is_at_most(300) }

    it 'allows valid GOG.com IDs' do
      expect(game).to allow_values(
        'divinity_2_developers_cut',
        'deus_ex_invisible_war',
        'toca_race_driver_3',
        'samorost_3',
        'z'
      ).for(:gog_id)
    end

    it 'disallows invalid GOG.com IDs' do
      expect(game).not_to allow_values(
        'Game with spaces in name',
        '<script></script>'
      ).for(:gog_id)
    end

    it { should validate_uniqueness_of(:igdb_id).allow_nil }
    it { should validate_length_of(:igdb_id).is_at_most(300) }

    it 'allows valid IGDB IDs' do
      expect(game).to allow_values(
        'divinity-2-developers-cut',
        'deus-ex-invisible-war',
        'toca-race-driver-3',
        'samorost-3',
        'z',
        '123',
        'foobar--1',
        'cat-president-~a-more-purrfect-union~' # this is valid for some reason
      ).for(:igdb_id)
    end

    it 'disallows invalid IGDB IDs' do
      expect(game).not_to allow_values(
        'Game with spaces in name',
        '<script></script>',
        'foo_underscore_bar',
        'foo_underscore_bar'
      ).for(:igdb_id)
    end

    it 'has an optional cover' do
      expect(game).not_to validate_attached_of(:cover)
      expect(game).to validate_content_type_of(:cover).rejecting([]).allowing('image/png', 'image/jpeg')
      expect(game).to validate_size_of(:cover).less_than(4.megabytes)
    end
  end

  describe 'Custom Validations' do
    let!(:wikidata_blocklist) { create(:wikidata_blocklist, wikidata_id: 420) }
    let(:game) { build(:game, wikidata_id: 420) }

    it 'fails validation if Wikidata ID is blocklisted' do
      wikidata_blocklist
      expect(game).to be_invalid
      expect(game.errors[:wikidata_id]).to include('is blocklisted')
    end
  end

  describe "Versioning" do
    it { should be_versioned }
  end

  describe "Associations" do
    it { should have_many(:game_purchases) }
    it { should have_many(:purchasers).through(:game_purchases).source(:user) }

    it { should have_many(:favorites) }
    it { should have_many(:favoriters).through(:favorites).source(:user) }

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

    it { should have_many(:steam_app_ids) }

    it { should belong_to(:series).optional }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
    it { should have_db_index(:giantbomb_id).unique }
    it { should have_db_index(:epic_games_store_id).unique }
    it { should have_db_index(:mobygames_id).unique }
    it { should have_db_index(:igdb_id).unique }
  end

  describe 'Scopes' do
    context 'with two games' do
      let(:game1) { create(:game, created_at: 4.hours.ago) }
      let(:game2) { create(:game, created_at: 1.hour.ago) }

      it "newest scope returns newest games first" do
        expect(Game.newest).to eq([game2, game1])
      end

      it "oldest scope returns oldest games first" do
        expect(Game.oldest).to eq([game1, game2])
      end
    end

    context 'with two games that have differing update times' do
      let(:game1) { create(:game, updated_at: 4.hours.ago) }
      let(:game2) { create(:game, updated_at: 1.hour.ago) }

      it "recently updated scope returns recently updated games first" do
        expect(Game.recently_updated).to eq([game2, game1])
      end

      it "least recently updated scope returns least recently updated games first" do
        expect(Game.least_recently_updated).to eq([game1, game2])
      end
    end

    context 'with three games where one has been favorited' do
      let(:user) { create(:confirmed_user) }
      let(:game1) { create(:game) }
      let(:game2) { create(:game) }
      let(:favorite_game) { create(:favorite_game, user: user, game: game2) }
      let(:game3) { create(:game) }

      it "the game with the most favorites comes first" do
        game1
        game3
        favorite_game
        expect(Game.most_favorites.first).to eq(game2)
      end

      it "sorting by favorites includes all games" do
        game1
        game3
        favorite_game
        expect(Game.most_favorites.length).to eq(3)
      end
    end

    context 'with two games where one has an owner' do
      let(:user) { create(:confirmed_user) }
      let(:game1) { create(:game) }
      let(:game2) { create(:game) }
      let(:game_purchase) { create(:game_purchase, user: user, game: game2) }

      it "the game with the most owners comes first" do
        # Make sure game1 is created first so that we can make sure the sorting
        # isn't just the order of ids.
        game1
        game_purchase
        expect(Game.most_owners).to eq([game2, game1])
      end
    end

    context 'with three games that have differing release dates' do
      let!(:game1) { create(:game, release_date: 2.days.ago) }
      let!(:game2) { create(:game, release_date: 1.day.ago) }
      let!(:game3) { create(:game, release_date: 3.days.ago) }

      it "the game with the most recent release date comes first" do
        expect(Game.recently_released).to eq([game2, game1, game3])
      end
    end

    context 'with three games where one is in the future' do
      let!(:game1) { create(:game, release_date: 2.days.ago) }
      let!(:game2) { create(:game, release_date: 1.day.ago) }
      let(:game3) { create(:game, release_date: 1.day.from_now) }

      it "only return the two released before today" do
        game3
        expect(Game.recently_released).to eq([game2, game1])
      end
    end

    context 'with three games where one has no release date' do
      let(:game1) { create(:game) }
      let!(:game2) { create(:game, release_date: 1.day.ago) }
      let!(:game3) { create(:game, release_date: 2.days.ago) }

      it "only return the two with release dates" do
        game1
        expect(Game.recently_released).to eq([game2, game3])
      end
    end

    context 'with three games where one was released today' do
      let!(:game1) { create(:game, release_date: 1.day.ago) }
      let!(:game2) { create(:game, release_date: Time.zone.today) }
      let!(:game3) { create(:game, release_date: 2.days.ago) }

      it "return all three in proper order" do
        expect(Game.recently_released).to eq([game2, game1, game3])
      end
    end

    context 'with three games with varying average ratings' do
      let!(:game1) { create(:game) }
      let!(:game2) { create(:game) }
      let!(:game3) { create(:game) }
      # rubocop:disable RSpec/LetSetup
      # These are necessary because the average rating scope depends on there
      # being at least 5 owners of the game with an actual rating.
      let!(:game_purchases1) { create_list(:game_purchase, 5, game: game1, rating: 30) }
      let!(:game_purchases2) { create_list(:game_purchase, 5, game: game2, rating: 10) }
      let!(:game_purchases3) { create_list(:game_purchase, 5, game: game3, rating: 50) }
      # rubocop:enable RSpec/LetSetup

      it "return all three in proper order" do
        expect(Game.highest_avg_rating).to eq([game3, game1, game2])
      end
    end

    context 'when sorting by average rating with three games where one has no ratings' do
      let!(:game1) { create(:game) }
      let!(:game2) { create(:game) }
      let!(:game3) { create(:game) }
      # rubocop:disable RSpec/LetSetup
      # These are necessary because the average rating scope depends on there
      # being at least 5 owners of the game with an actual rating.
      let!(:game_purchases1) { create_list(:game_purchase, 5, game: game1, rating: 30) }
      let!(:game_purchases2) { create_list(:game_purchase, 5, game: game2, rating: 60) }
      let!(:game_purchases3) { create_list(:game_purchase, 5, game: game3, rating: nil) }
      # rubocop:enable RSpec/LetSetup

      it "return the two non-nil games in proper order" do
        expect(Game.highest_avg_rating).to eq([game2, game1])
      end
    end

    context 'with three games where two have platforms and one does not' do
      let(:platform1) { create(:platform) }
      let(:platform2) { create(:platform) }
      let(:game1) { create(:game, platforms: [platform1]) }
      let(:game2) { create(:game, platforms: [platform2]) }
      let(:game3) { create(:game, platforms: []) }

      it 'filtering by platforms only returns relevant games' do
        game1
        game2
        game3
        expect(Game.on_platform(platform1.id)).to eq([game1])
        expect(Game.on_platform(platform2.id)).to eq([game2])
      end
    end

    context 'with three games where each was made in a different year' do
      let!(:game2014) { create(:game, release_date: Faker::Date.between(from: 'January 1, 2014', to: 'December 31, 2014')) }
      let!(:game2017) { create(:game, release_date: Faker::Date.between(from: 'January 1, 2017', to: 'December 31, 2017')) }
      let!(:game2018) { create(:game, release_date: Faker::Date.between(from: 'January 1, 2018', to: 'December 31, 2018')) }
      let(:game_no_release_date) { create(:game, release_date: nil) }

      it 'filtering by year only returns relevant games' do
        game_no_release_date
        expect(Game.by_year(2014)).to eq([game2014])
        expect(Game.by_year(2017)).to eq([game2017])
        expect(Game.by_year(2018)).to eq([game2018])
      end
    end
  end

  describe 'Destructions' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
    let(:favorite_game) { create(:favorite_game, user: user, game: game) }
    let(:game_with_platform) { create(:game, :platform) }
    let(:game_with_genre) { create(:game, :genre) }
    let(:game_with_engine) { create(:game, :engine) }
    let(:game_with_developer) { create(:game, :developer) }
    let(:game_with_publisher) { create(:game, :publisher) }
    let(:game_with_series) { create(:game, :series) }

    it 'Game purchase should be deleted when game is deleted' do
      game_purchase
      expect { game.destroy }.to change(GamePurchase, :count).by(-1)
    end

    it 'FavoriteGame should be deleted when game is deleted' do
      favorite_game
      expect { game.destroy }.to change(FavoriteGame, :count).by(-1)
    end

    it 'GamePlatform should be deleted when game is deleted' do
      game_with_platform
      expect { game_with_platform.destroy }.to change(GamePlatform, :count).by(-1)
    end

    it 'GameGenre should be deleted when game is deleted' do
      game_with_genre
      expect { game_with_genre.destroy }.to change(GameGenre, :count).by(-1)
    end

    it 'GameEngine should be deleted when game is deleted' do
      game_with_engine
      expect { game_with_engine.destroy }.to change(GameEngine, :count).by(-1)
    end

    it 'GameDeveloper should be deleted when game is deleted' do
      game_with_developer
      expect { game_with_developer.destroy }.to change(GameDeveloper, :count).by(-1)
    end

    it 'GamePublisher should be deleted when game is deleted' do
      game_with_publisher
      expect { game_with_publisher.destroy }.to change(GamePublisher, :count).by(-1)
    end

    it 'Series should not be deleted when game is deleted' do
      game_with_series
      expect { game_with_series.destroy }.to change(Series, :count).by(0)
    end
  end
end
