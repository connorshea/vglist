# typed: false
require 'rails_helper'

RSpec.describe Series, type: :model do
  subject(:series) { build(:series) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(series).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }

    it { should validate_uniqueness_of(:wikidata_id) }
    it 'validates numericality' do
      expect(series).to validate_numericality_of(:wikidata_id)
        .only_integer
        .allow_nil
        .is_greater_than(0)
    end
  end

  describe "Versioning" do
    it { should be_versioned }
  end

  describe "Associations" do
    it { should have_many(:games) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
  end

  describe 'Destructions' do
    let(:series) { create(:series) }
    let(:game_with_series) { create(:game, series: series) }

    it 'Game should not be deleted when series is deleted' do
      game_with_series
      expect { series.destroy }.to change(Game, :count).by(0)
    end

    it "Game shouldn't have a series_id after series is deleted" do
      game_with_series
      series.destroy!
      expect(game_with_series.reload.series_id).to be(nil)
    end
  end
end
