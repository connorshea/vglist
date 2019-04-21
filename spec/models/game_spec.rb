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
    it { should have_db_index(:wikidata_id).unique }
    it { should have_db_index(:steam_app_id).unique }
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
      let(:favorite) { create(:favorite, user: user, favoritable: game2) }
      let(:game3) { create(:game) }

      it "the game with the most favorites comes first" do
        favorite
        expect(Game.most_popular).to eq([game2, game1, game3])
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
  end

  describe 'Destructions' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
    let(:favorite) { create(:favorite, user: user, favoritable: game) }
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

    it 'Favorite should be deleted when game is deleted' do
      favorite
      expect { game.destroy }.to change(Favorite, :count).by(-1)
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
