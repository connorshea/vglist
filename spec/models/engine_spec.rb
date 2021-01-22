# typed: false
require 'rails_helper'

RSpec.describe Engine, type: :model do
  subject(:engine) { build(:engine) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(engine).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality' do
      expect(engine).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end
  end

  describe "Versioning" do
    it { should be_versioned }
  end

  describe "Associations" do
    it { should have_many(:game_engines) }
    it { should have_many(:games).through(:game_engines).source(:game) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
  end

  describe 'Destructions' do
    let(:engine) { create(:engine) }
    let(:game_with_engine) { create(:game, engines: [engine]) }

    it 'GameEngine should be deleted when engine is deleted' do
      game_with_engine
      expect { engine.destroy }.to change(GameEngine, :count).by(-1)
    end

    it 'Game should not be deleted when engine is deleted' do
      game_with_engine
      expect { engine.destroy }.to change(Game, :count).by(0)
    end
  end
end
