# typed: false
require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "Query for data on users" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:user_with_avatar) { create(:confirmed_user_with_avatar) }
    let(:application_for_user_with_avatar) { build(:application, owner: user_with_avatar) }
    let(:access_token_for_user_with_avatar) { create(:access_token, resource_owner_id: user_with_avatar.id, application: application_for_user_with_avatar) }
    let(:private_user) { create(:private_user) }

    it "returns basic data for user" do
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

      result = api_request(query_string, variables: { id: user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns basic data for user when searching by username" do
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

      result = api_request(query_string, variables: { username: user.username }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns basic data for user when searching by slug" do
      query_string = <<-GRAPHQL
        query($slug: String!) {
          user(slug: $slug) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { slug: user.slug }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns an error if the query uses both an id and username" do
      query_string = <<-GRAPHQL
        query($id: ID!, $username: String!) {
          user(id: $id, username: $username) {
            id
            username
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: user.id, username: user.username }, token: access_token)

      expect(result.graphql_dig(:user)).to be_nil
      expect(result.to_h["errors"].first['message']).to eq('Cannot provide more than one argument to user at a time.')
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

      result = api_request(query_string, variables: { id: user_with_avatar.id }, token: access_token_for_user_with_avatar)

      avatar_variant = user_with_avatar.sized_avatar(:small)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user_with_avatar.id.to_s,
          username: user_with_avatar.username,
          avatarUrl: Rails.application.routes.url_helpers.rails_representation_url(avatar_variant)
        }
      )
    end

    it "returns only public data for private user" do
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
            followers {
              nodes {
                id
              }
            }
            following {
              nodes {
                id
              }
            }
            favoritedGames {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: private_user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: private_user.id.to_s,
          username: private_user.username,
          bio: nil,
          gamePurchases: nil,
          activity: nil,
          followers: nil,
          following: nil,
          favoritedGames: nil
        }
      )
    end

    it "returns activity for user" do
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

      result = api_request(query_string, variables: { id: user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          activity: {
            nodes: [
              {
                id: user.events.first.id,
                eventable: {
                  id: user.id.to_s,
                  __typename: "User"
                }
              }
            ]
          }
        }
      )
    end

    it "returns data for users when listing" do
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

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:users, :nodes)).to include(
        {
          id: user.id.to_s,
          username: user.username
        },
        {
          id: user2.id.to_s,
          username: user2.username
        }
      )
    end

    it "returns data for a user when searching" do
      user
      query_string = <<-GRAPHQL
        query($query: String!) {
          userSearch(query: $query) {
            nodes {
              id
              username
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: user.username }, token: access_token)

      expect(result.graphql_dig(:user_search, :nodes)).to eq(
        [{
          id: user.id.to_s,
          username: user.username
        }]
      )
    end

    context 'with favoritedGames' do
      let!(:favorite_game) { create(:favorite_game, user: user) }

      it "returns data for current user's favorite games when requesting favoritedGames" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              favoritedGames {
                nodes {
                  id
                  name
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :favorited_games, :nodes)).to include(
          {
            id: favorite_game.game.id.to_s,
            name: favorite_game.game.name
          }
        )
      end
    end

    context 'with isFollowed field' do
      let(:relationship) { create(:relationship, follower: user, followed: user2) }

      it "returns true for current user that follows this user" do
        relationship
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              isFollowed
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)

        expect(result.graphql_dig(:user)).to eq(
          {
            isFollowed: true
          }
        )
      end

      it "returns false for current user that doesn't follow this user" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              isFollowed
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)

        expect(result.graphql_dig(:user)).to eq(
          {
            isFollowed: false
          }
        )
      end

      it "returns null for current user that is looking at themselves" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              isFollowed
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user)).to eq(
          {
            isFollowed: nil
          }
        )
      end
    end

    context 'with currentUser' do
      it "returns data for current user when requesting currentUser" do
        user
        query_string = <<-GRAPHQL
          query {
            currentUser {
              id
              username
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:current_user)).to eq(
          {
            id: user.id.to_s,
            username: user.username
          }
        )
      end
    end
  end
end
