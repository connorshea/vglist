# typed: false
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

      expect(result["data"]["activity"]["nodes"]).to include(
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "GamePurchase"
          }
        },
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "User"
          }
        }
      )
      expect(result["data"]["activity"]["nodes"].length).to eq(2)
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

      expect(result["data"]["activity"]["nodes"]).to include(
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "FavoriteGame",
            "id" => favorite_game.id.to_s
          }
        },
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "Relationship",
            "id" => relationship.id.to_s
          }
        },
        {
          "user" => {
            "username" => user2.username
          },
          "eventable" => {
            "__typename" => "User",
            "id" => user2.id.to_s
          }
        },
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "GamePurchase",
            "id" => game_purchase.id.to_s
          }
        },
        {
          "user" => {
            "username" => user.username
          },
          "eventable" => {
            "__typename" => "User",
            "id" => user.id.to_s
          }
        }
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
      expect(result["data"]["activity"]["nodes"]).to eq(
        [
          {
            "user" => {
              "username" => user.username
            },
            "eventable" => {
              "__typename" => "Relationship"
            }
          },
          {
            "user" => {
              "username" => user2.username
            },
            "eventable" => {
              "__typename" => "User"
            }
          },
          {
            "user" => {
              "username" => user.username
            },
            "eventable" => {
              "__typename" => "User"
            }
          }
        ]
      )
    end
  end
end
