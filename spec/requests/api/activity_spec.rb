# typed: false
require 'rails_helper'

RSpec.describe "Activity API", type: :request do
  describe "Query for data on activity globally" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:user3) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:favorite_game) { create(:favorite_game, user: user) }

    it "returns basic data for activity events" do
      sign_in(user)
      game_purchase
      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            user {
              username
            }
            eventable {
              __typename
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )

      expect(result.to_h["data"]["activity"]).to eq(
        [
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
        ]
      )
    end

    it "returns data for various types of activity events" do
      sign_in(user)
      game_purchase
      relationship
      favorite_game

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
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
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )

      expect(result.to_h["data"]["activity"]).to eq(
        [
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
        ]
      )
    end

    it "returns basic data for 'following' activity" do
      sign_in(user)
      user2
      user3
      relationship
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            user {
              username
            }
            eventable {
              __typename
            }
          }
        }
      GRAPHQL

      result = VideoGameListSchema.execute(
        query_string,
        context: { current_user: user }
      )

      # Doesn't include user3 because user isn't following them.
      expect(result.to_h["data"]["activity"]).to eq(
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
