# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Company, type: :model do
  subject(:company) { build(:company) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(company).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it { should validate_presence_of(:wikidata_id) }
    it 'validates numericality' do
      expect(company).to validate_numericality_of(:wikidata_id)
        .only_integer
        .is_greater_than(0)
    end
  end

  describe "Versioning" do
    it { should be_versioned }
  end

  describe "Associations" do
    it { should have_many(:game_developers).dependent(:destroy) }
    it { should have_many(:developed_games).through(:game_developers).source(:game) }
    it { should have_many(:game_publishers).dependent(:destroy) }
    it { should have_many(:published_games).through(:game_publishers).source(:game) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
    it { should have_db_index([:games_count, :id]) }
  end

  # Kept up to date by GameDeveloper and GamePublisher callbacks (CompanyGamesCount).
  describe "Games count" do
    let(:company) { create(:company) }
    let(:other_company) { create(:company) }
    let(:game) { create(:game) }

    define_method(:games_count) { company.reload.games_count }

    it "counts developed and published games" do
      create(:game, developers: [company])
      create(:game, publishers: [company])
      expect(games_count).to eq(2)
    end

    it "counts a game the company both developed and published once" do
      create(:game, developers: [company], publishers: [company])
      expect(games_count).to eq(1)
    end

    it "goes down when a game loses the company, but not while the other role keeps it" do
      game.update!(developers: [company], publishers: [company])

      game.update!(publishers: [])
      expect(games_count).to eq(1)

      game.update!(developers: [])
      expect(games_count).to eq(0)
    end

    it "goes down when the game is deleted" do
      game.update!(developers: [company])
      game.destroy!
      expect(games_count).to eq(0)
    end

    it "moves with a row that's reassigned to another company" do
      game_developer = create(:game_developer, game: game, company: company)
      game_developer.update!(company: other_company)

      expect(games_count).to eq(0)
      expect(other_company.reload.games_count).to eq(1)
    end

    it "goes down when the game's developers are replaced" do
      game.update!(developers: [company])
      game.update!(developer_ids: [other_company.id])

      expect(games_count).to eq(0)
      expect(other_company.reload.games_count).to eq(1)
    end
  end

  describe 'Destructions' do
    let(:company) { create(:company) }
    let(:game_with_developer) { create(:game, developers: [company]) }
    let(:game_with_publisher) { create(:game, publishers: [company]) }

    it 'GameDeveloper should be deleted when company is deleted' do
      game_with_developer
      expect { company.destroy }.to change(GameDeveloper, :count).by(-1)
    end

    it 'Game should not be deleted when developer is deleted' do
      game_with_developer
      expect { company.destroy }.not_to change(Game, :count)
    end

    it 'GamePublisher should be deleted when company is deleted' do
      game_with_publisher
      expect { company.destroy }.to change(GamePublisher, :count).by(-1)
    end

    it 'Game should not be deleted when publisher is deleted' do
      game_with_publisher
      expect { company.destroy }.not_to change(Game, :count)
    end
  end
end
