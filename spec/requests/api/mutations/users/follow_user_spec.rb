# frozen_string_literal: true

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

    it "returns an error when trying to follow a private user" do
      private_user = create(:private_user)

      expect do
        result = api_request(query_string, variables: { id: private_user.id }, token: access_token)

        expect(api_result_errors(result)).to include("You aren't allowed to follow this user.")
      end.not_to change(Relationship, :count)
    end

    it "returns an error when trying to follow yourself" do
      expect do
        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(api_result_errors(result)).to include("You aren't allowed to follow this user.")
      end.not_to change(Relationship, :count)
    end
  end
end
