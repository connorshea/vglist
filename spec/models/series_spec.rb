require 'rails_helper'

RSpec.describe Series, type: :model do
  subject(:series) { FactoryBot.create(:series) }

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

  describe "Associations" do
    it { should have_many(:games) }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
  end
end
