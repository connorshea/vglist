# typed: false
require 'rails_helper'

RSpec.describe SteamBlocklist, type: :model do
  subject(:steam_blocklist) { build(:steam_blocklist) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(steam_blocklist).to be_valid
    end

    it { should validate_presence_of(:steam_app_id) }
    it { should validate_uniqueness_of(:steam_app_id) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(120) }
  end

  describe "Associations" do
    it { should belong_to(:user).optional }
  end

  describe "Indexes" do
    it { should have_db_index(:steam_app_id).unique }
  end

  describe "Deletions" do
    let(:admin) { create(:confirmed_admin) }
    let(:steam_blocklist) { create(:steam_blocklist, user: admin) }

    it 'Blocklist entry shouldn\'t be deleted when user is deleted' do
      steam_blocklist
      expect { admin.destroy }.to change(SteamBlocklist, :count).by(0)
    end
  end
end
