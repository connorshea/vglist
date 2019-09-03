# typed: false
require 'rails_helper'

RSpec.describe Relationship, type: :model do
  subject(:relationship) { FactoryBot.create(:relationship) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(relationship).to be_valid
    end

    it { should validate_presence_of(:follower_id) }
    it { should validate_presence_of(:followed_id) }

    it { should validate_uniqueness_of(:follower_id).scoped_to(:followed_id) }
  end

  describe "Associations" do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end

  describe "Indexes" do
    it { should have_db_index([:follower_id, :followed_id]).unique }
  end

  describe 'Destructions' do
    let(:follower) { create(:confirmed_user) }
    let(:followed) { create(:confirmed_user) }
    let(:relationship) { create(:relationship, follower: follower, followed: followed) }

    it 'Follower should not be deleted when Relationship is deleted' do
      relationship
      expect { relationship.destroy }.to change(User, :count).by(0)
    end
  end
end
