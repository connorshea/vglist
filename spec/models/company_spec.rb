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
end
