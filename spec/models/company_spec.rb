# typed: false
require 'rails_helper'

RSpec.describe Company, type: :model do
  subject(:company) { FactoryBot.create(:company) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(company).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality' do
      expect(company).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end
  end

  describe "Associations" do
    it { should have_many(:game_developers) }
    it { should have_many(:developed_games).through(:game_developers).source(:game) }
    it { should have_many(:game_publishers) }
    it { should have_many(:published_games).through(:game_publishers).source(:game) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
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
      expect { company.destroy }.to change(Game, :count).by(0)
    end

    it 'GamePublisher should be deleted when company is deleted' do
      game_with_publisher
      expect { company.destroy }.to change(GamePublisher, :count).by(-1)
    end

    it 'Game should not be deleted when publisher is deleted' do
      game_with_publisher
      expect { company.destroy }.to change(Game, :count).by(0)
    end
  end
end
