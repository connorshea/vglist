# typed: false
require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "Query for data on users" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:user_with_avatar) { create(:confirmed_user_with_avatar) }
    let(:private_user) { create(:private_user) }

    it "returns basic data for user" do
      sign_in(user)
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: user.id }
      )

      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user.id.to_s,
          "username" => user.username,
          "role" => user.role.upcase,
          "privacy" => user.privacy.upcase,
          "avatarUrl" => nil
        }
      )
    end

    it "returns basic data for user when searching by username" do
      sign_in(user)
      query_string = <<-GRAPHQL
        query($username: String!) {
          user(username: $username) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { username: user.username }
      )

      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user.id.to_s,
          "username" => user.username,
          "role" => user.role.upcase,
          "privacy" => user.privacy.upcase,
          "avatarUrl" => nil
        }
      )
    end

    it "returns avatar for user" do
      sign_in(user_with_avatar)
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            avatarUrl
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user_with_avatar },
        variables: { id: user_with_avatar.id }
      )

      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user_with_avatar.id.to_s,
          "username" => user_with_avatar.username,
          "avatarUrl" => Rails.application.routes.url_helpers.rails_blob_url(user_with_avatar.avatar_attachment, only_path: true)
        }
      )
    end

    it "returns only public data for private user" do
      sign_in(user)

      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            bio
            gamePurchases {
              nodes {
                id
              }
            }
            activity {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: private_user.id }
      )

      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => private_user.id.to_s,
          "username" => private_user.username,
          "bio" => nil,
          "gamePurchases" => nil,
          "activity" => nil
        }
      )
    end

    it "returns activity for user" do
      sign_in(user)

      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            activity {
              nodes {
                id
                eventable {
                  __typename
                  ... on User {
                    id
                  }
                  ... on GamePurchase {
                    id
                  }
                  ... on Relationship {
                    id
                  }
                  ... on FavoriteGame {
                    id
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user },
        variables: { id: user.id }
      )

      expect(result.to_h["data"]["user"]).to eq(
        {
          "id" => user.id.to_s,
          "username" => user.username,
          "activity" => {
            "nodes" => [
              {
                "id" => user.events.first.id,
                "eventable" => {
                  "id" => user.id.to_s,
                  "__typename" => "User"
                }
              }
            ]
          }
        }
      )
    end

    it "returns data for users when listing" do
      sign_in(user)
      user
      user2
      query_string = <<-GRAPHQL
        query {
          users {
            nodes {
              id
              username
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )
      expect(result.to_h["data"]["users"]["nodes"]).to include(
        {
          "id" => user.id.to_s,
          "username" => user.username
        },
        {
          "id" => user2.id.to_s,
          "username" => user2.username
        }
      )
    end
  end
end
