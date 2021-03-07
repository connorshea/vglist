# typed: false
require 'rails_helper'

RSpec.describe "FollowUser Mutation API", type: :request do
  describe "Mutation creates a new Relationship" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
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
      user2

      expect do
        api_request(query_string, variables: { id: user2.id }, token: access_token)
      end.to change(Relationship, :count).by(1)
    end

    it "returns basic data for user after following them" do
      user2

      result = api_request(query_string, variables: { id: user2.id }, token: access_token)

      expect(result.graphql_dig(:follow_user, :user)).to eq(
        {
          id: user2.id.to_s,
          username: user2.username
        }
      )
    end
  end
end
