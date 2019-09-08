# typed: false
require 'rails_helper'

RSpec.describe "Relationships", type: :request do
  describe "POST user_follow_path" do
    let(:user1) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }

    it "creates a follow" do
      sign_in(user1)
      user2

      expect do
        post user_follow_path(user_id: user2.id)
      end.to change(Relationship, :count).by(1)
    end
  end

  describe "DELETE user_unfollow_path" do
    let(:user1) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:relationship) { create(:relationship, follower: user1, followed: user2) }

    it "deletes a follow" do
      sign_in(user1)
      relationship

      expect do
        delete user_unfollow_path(user_id: user2.id)
      end.to change(Relationship, :count).by(-1)
    end
  end
end
