# typed: false
require 'rails_helper'

RSpec.describe "FollowUser Mutation API", type: :request do
  describe "Mutation creates a new Relationship" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          followUser(userId: $id) {
            user {
              id
              username
            }
          }
        }
      GRAPHQL
    end

    it "creates a new Relationship record" do
      sign_in(user)
      user2

      expect do
        VideoGameListSchema.execute(
          query_string,
          context: { current_user: user },
          variables: { id: user2.id }
        )
      end.to change(Relationship, :count).by(1)
    end

    it "returns basic data for user after following them" do
      sign_in(user)
      user2

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: user2.id }
      )

      expect(result.to_h["data"]["followUser"]["user"]).to eq(
        {
          "id" => user2.id.to_s,
          "username" => user2.username
        }
      )
    end
  end
end
