require 'rails_helper'

RSpec.describe "Activity API", type: :request do
  describe "Query for data on activity globally" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:user3) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game_purchase) { create(:game_purchase, user: user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:favorite_game) { create(:favorite_game, user: user) }

    it "returns basic data for activity events" do
      user
      game_purchase
      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user {
                username
              }
              eventable {
                __typename
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:activity, :nodes)).to include(
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "GamePurchase"
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "User"
          }
        }
      )
      expect(result.graphql_dig(:activity, :nodes).length).to eq(2)
    end

    it "returns data for various types of activity events" do
      user
      game_purchase
      relationship
      favorite_game

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user {
                username
              }
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
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:activity, :nodes)).to include(
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "FavoriteGame",
            id: favorite_game.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "Relationship",
            id: relationship.id.to_s
          }
        },
        {
          user: {
            username: user2.username
          },
          eventable: {
            __typename: "User",
            id: user2.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "GamePurchase",
            id: game_purchase.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "User",
            id: user.id.to_s
          }
        }
      )
    end

    it "returns eventable fields used by the activity feed frontend" do
      game_purchase
      relationship
      favorite_game

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              eventCategory
              user {
                id
                username
                slug
              }
              eventable {
                ... on GamePurchase {
                  game { id name }
                  completionStatus
                }
                ... on FavoriteGame {
                  game { id name }
                }
                ... on Relationship {
                  followed { id username slug }
                }
                ... on User {
                  id
                  username
                  slug
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      # Find nodes by event category
      favorite_node = nodes.find { |n| n[:eventCategory] == "FAVORITE_GAME" }
      relationship_node = nodes.find { |n| n[:eventCategory] == "FOLLOWING" }
      add_to_library_node = nodes.find { |n| n[:eventCategory] == "ADD_TO_LIBRARY" }
      new_user_nodes = nodes.select { |n| n[:eventCategory] == "NEW_USER" }

      # GamePurchase eventable returns game name and id
      expect(add_to_library_node[:eventable][:game][:name]).to eq(game_purchase.game.name)
      expect(add_to_library_node[:eventable][:game][:id]).to eq(game_purchase.game.id.to_s)

      # FavoriteGame eventable returns game name and id
      expect(favorite_node[:eventable][:game][:name]).to eq(favorite_game.game.name)
      expect(favorite_node[:eventable][:game][:id]).to eq(favorite_game.game.id.to_s)

      # Relationship eventable returns followed user details
      expect(relationship_node[:eventable][:followed][:username]).to eq(user2.username)
      expect(relationship_node[:eventable][:followed][:slug]).to eq(user2.slug)

      # User (NEW_USER) eventable returns user details
      expect(new_user_nodes).not_to be_empty
      new_user_node = new_user_nodes.first
      expect(new_user_node[:eventable][:username]).to be_present
      expect(new_user_node[:eventable][:slug]).to be_present
    end

    it "returns completionStatus on GamePurchase eventable when set" do
      game_purchase_with_status = create(:game_purchase, :completion_status, user: user)
      # Trigger the event by creating the game purchase above (which auto-creates an event)

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              eventCategory
              eventable {
                ... on GamePurchase {
                  game { id name }
                  completionStatus
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      add_to_library_node = nodes.find do |n|
        n[:eventCategory] == "ADD_TO_LIBRARY" &&
          n.dig(:eventable, :game, :id) == game_purchase_with_status.game.id.to_s
      end

      expect(add_to_library_node).not_to be_nil
      expect(add_to_library_node.dig(:eventable, :completionStatus)).to eq(
        game_purchase_with_status.completion_status.upcase
      )
    end

    it "returns basic data for 'following' activity" do
      user
      user2
      user3
      relationship
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              user {
                username
              }
              eventable {
                __typename
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      # Doesn't include user3 because user isn't following them.
      expect(result.graphql_dig(:activity, :nodes)).to eq(
        [
          {
            user: {
              username: user.username
            },
            eventable: {
              __typename: "Relationship"
            }
          },
          {
            user: {
              username: user2.username
            },
            eventable: {
              __typename: "User"
            }
          },
          {
            user: {
              username: user.username
            },
            eventable: {
              __typename: "User"
            }
          }
        ]
      )
    end

    it "returns following feed with eventable details" do
      relationship
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              eventCategory
              eventable {
                ... on Relationship {
                  followed { id username slug }
                }
                ... on User {
                  id
                  username
                  slug
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      relationship_node = nodes.find { |n| n[:eventCategory] == "FOLLOWING" }
      expect(relationship_node[:eventable][:followed][:username]).to eq(user2.username)
      expect(relationship_node[:eventable][:followed][:slug]).to eq(user2.slug)
    end

    it "excludes private users from global activity feed" do
      private_user = create(:private_user)
      create(:game_purchase, user: private_user)

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user { username }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)
      usernames = nodes.map { |n| n.dig(:user, :username) }

      expect(usernames).not_to include(private_user.username)
    end

    it "returns an error when querying following feed without authentication" do
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              eventCategory
            }
          }
        }
      GRAPHQL

      post graphql_path,
        params: { query: query_string }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to eq("You must be logged in to view the following feed.")
    end
  end
end
