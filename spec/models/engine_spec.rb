require 'rails_helper'

RSpec.describe Engine, type: :model do
  subject(:engine) { FactoryBot.create(:engine) }

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

  describe "Associations" do
    it { should have_many(:game_engines) }
    it { should have_many(:games).through(:game_engines).source(:game) }
  end
end
