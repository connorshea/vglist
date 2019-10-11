# typed: false
require 'rails_helper'

RSpec.describe "UnfollowUser Mutation API", type: :request do
  describe "Mutation unfollows a user" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          unfollowUser(userId: $id) {
            user {
              id
              username
            }
          }
        }
      GRAPHQL
    end

    it "unfollows a user" do
      sign_in(user)
      relationship

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: user2.id }
        )
      end.to change(Relationship, :count).by(-1)
    end

    it "returns basic data for user after unfollowing them" do
      sign_in(user)
      relationship

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: user2.id }
      )

      expect(result.to_h["data"]["unfollowUser"]["user"]).to eq(
        {
          "id" => user2.id.to_s,
          "username" => user2.username
        }
      )
    end
  end
end
