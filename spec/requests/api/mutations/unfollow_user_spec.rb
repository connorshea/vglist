# typed: false
require 'rails_helper'

RSpec.describe "UnfollowUser Mutation API", type: :request do
  describe "Mutation unfollows a user" do
    let(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
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
      relationship

      expect do
        api_request(query_string, variables: { id: user2.id }, token: access_token)
      end.to change(Relationship, :count).by(-1)
    end

    it "returns basic data for user after unfollowing them" do
      relationship

      result = api_request(query_string, variables: { id: user2.id }, token: access_token)

      expect(result.graphql_dig(:unfollowUser, :user)).to eq(
        {
          id: user2.id.to_s,
          username: user2.username
        }
      )
    end
  end
end
