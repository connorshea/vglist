# typed: false
require 'rails_helper'

RSpec.describe Relationship, type: :model do
  subject(:relationship) { build(:relationship) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(relationship).to be_valid
    end

    it { should validate_presence_of(:follower_id) }
    it { should validate_presence_of(:followed_id) }

    it { should validate_uniqueness_of(:follower_id).scoped_to(:followed_id) }
  end

  describe "Custom Validations" do
    let(:user) { create(:confirmed_user) }

    it "doesn't let a User follow themselves" do
      relationship = Relationship.create(followed: user, follower: user)
      relationship.valid?
      expect(relationship.errors[:follower_id]).to eq(["can't follow themselves"])
    end
  end

  describe "Associations" do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
    it { should have_many(:relationship_events).dependent(:destroy) }
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

    it 'Follower should not be deleted when Followed is deleted' do
      relationship
      expect { followed.destroy }.to change(User, :count).by(-1)
    end

    it 'Followed User should not be deleted when Follower is deleted' do
      relationship
      expect { follower.destroy }.to change(User, :count).by(-1)
    end

    it 'Relationship should be deleted when Follower User is deleted' do
      relationship
      expect { follower.destroy }.to change(Relationship, :count).by(-1)
    end

    it 'Relationship should be deleted when Followed User is deleted' do
      relationship
      expect { followed.destroy }.to change(Relationship, :count).by(-1)
    end
  end
end
