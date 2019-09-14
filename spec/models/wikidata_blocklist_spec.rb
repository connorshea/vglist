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

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(120) }
  end

  describe "Associations" do
    it { should belong_to(:user).optional }
  end

  describe "Indexes" do
    it { should have_db_index(:wikidata_id).unique }
  end

  describe "Deletions" do
    let(:admin) { create(:confirmed_admin) }
    let(:wikidata_blocklist) { create(:wikidata_blocklist, user: admin) }

    it 'Blocklist entry shouldn\'t be deleted when user is deleted' do
      wikidata_blocklist
      expect { admin.destroy }.to change(WikidataBlocklist, :count).by(0)
    end
  end
end
