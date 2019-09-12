# typed: false
require 'rails_helper'

RSpec.describe WikidataBlocklist, type: :model do
  subject(:wikidata_blocklist) { FactoryBot.create(:wikidata_blocklist) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(wikidata_blocklist).to be_valid
    end

    it { should validate_presence_of(:wikidata_id) }
    it { should validate_uniqueness_of(:wikidata_id) }
  end
end
